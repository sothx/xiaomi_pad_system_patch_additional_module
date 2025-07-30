#!/bin/bash
# shellcheck disable=SC2086
set -e

# 获取脚本所在目录（避免相对路径错误）
workfile="$(cd "$(dirname "$0")" && pwd)"
ExtractErofs="$workfile/common/binary/extract.erofs"
GETTYPE="$workfile/common/binary/gettype"
ImageExtRactorLinux="$workfile/common/binary/imgextractorLinux"

# 确保工具文件存在并设置正确权限
for tool in "$ExtractErofs" "$GETTYPE" "$ImageExtRactorLinux"; do
    if [ ! -f "$tool" ]; then
        echo "❌ 错误：工具文件 $tool 不存在" >&2
        exit 1
    fi
done
chmod u+x "$ImageExtRactorLinux" || { echo "❌ 无法设置 $ImageExtRactorLinux 权限" >&2; exit 1; }
chmod +x "$ExtractErofs" || { echo "❌ 无法设置 $ExtractErofs 权限" >&2; exit 1; }
chmod +x "$GETTYPE" || { echo "❌ 无法设置 $GETTYPE 权限" >&2; exit 1; }

# 工作目录和输出目录
TMPDir="$workfile/tmp/"
DistDir="$workfile/dist/"
payload_img_dir="${TMPDir}payload_img/"
pre_patch_file_dir="${TMPDir}pre_patch_file/"
patch_mods_dir="${TMPDir}patch_mods/"
release_dir="${TMPDir}release/"

# 参数初始化
input_rom_version=""
input_rom_url=""
input_android_target_version="15"

input_rom_url="$1"
# 检查必须参数
if [ -z "$input_rom_url" ]; then
    echo "❌ 错误：必须提供 --url 参数。" >&2
    echo "用法：bash ./build.sh <ROM_URL>" >&2
    exit 1
fi

echo "🧹 清理并准备临时目录..."
sudo rm -rf "$TMPDir" || { echo "❌ 无法清理临时目录 $TMPDir" >&2; exit 1; }
mkdir -p "$TMPDir" "$DistDir" "$payload_img_dir" "$pre_patch_file_dir" "$patch_mods_dir" "$release_dir" || { echo "❌ 无法创建目录" >&2; exit 1; }

echo "🔍 检查 payload_dumper 是否可用..."
if ! command -v payload_dumper >/dev/null 2>&1; then
    echo "❌ 错误：payload_dumper 未安装或不在 PATH 中。" >&2
    echo "请安装它，例如：" >&2
    echo "  pipx install git+https://github.com/5ec1cff/payload-dumper" >&2
    exit 1
fi

echo "⬇️ 获取 system_ext.img..."
payload_dumper --partitions system_ext --out "$payload_img_dir" "$input_rom_url" || { echo "❌ payload_dumper 失败" >&2; exit 1; }

if [ ! -f "${payload_img_dir}system_ext.img" ]; then
    echo "❌ 找不到 system_ext.img" >&2
    exit 1
fi

# 根据镜像格式选择工具
echo "📦 检测 system_ext.img 文件格式..."
if [[ $("$GETTYPE" -i "${payload_img_dir}system_ext.img") == "ext" ]]; then
    echo "📦 使用 imgextractorLinux 解包 system_ext.img..."
    sudo "$ImageExtRactorLinux" "${payload_img_dir}system_ext.img" "$pre_patch_file_dir" || { echo "❌ imgextractorLinux 解包失败" >&2; exit 1; }
elif [[ $("$GETTYPE" -i "${payload_img_dir}system_ext.img") == "erofs" ]]; then
    echo "📦 使用 extract.erofs 解包 system_ext.img..."
    "$ExtractErofs" \
        -i "${payload_img_dir}system_ext.img" \
        -x -c "$workfile/common/system_ext_unpak_list.txt" \
        -o "$pre_patch_file_dir" || { echo "❌ extract.erofs 解包失败" >&2; exit 1; }
else
    echo "❌ 不支持的镜像解压方式"
    exit 1
fi

# 检查提取文件
system_ext_unpak_list_file="$workfile/common/system_ext_unpak_list.txt"
echo "✅ 校验解包文件是否提取成功..."

if [ ! -f "$system_ext_unpak_list_file" ]; then
    echo "❌ 缺失列表文件: $system_ext_unpak_list_file" >&2
    exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
    file=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$file" ] && continue

    full_path="${pre_patch_file_dir}system_ext${file}"
    echo "🔍 检查文件: $full_path"

    if [ ! -f "$full_path" ]; then
        echo "❌ 缺失文件: system_ext${file}" >&2
        exit 1
    fi
done < "$system_ext_unpak_list_file"

if [ -f "${pre_patch_file_dir}system_ext/etc/build.prop" ]; then
    input_rom_version=$(grep '^ro.system_ext.build.version.incremental=' "${pre_patch_file_dir}system_ext/etc/build.prop" | cut -d'=' -f2)
    if [ -z "$input_rom_version" ]; then
        echo "Error: ro.system_ext.build.version.incremental not found in build.prop" >&2
        exit 1
    fi
else
    echo "Error: build.prop file not found at ${pre_patch_file_dir}system_ext/etc/build.prop" >&2
    exit 1
fi

if [ -f "${pre_patch_file_dir}system_ext/etc/build.prop" ]; then
    input_android_target_version=$(grep '^ro.system_ext.build.version.release=' "${pre_patch_file_dir}system_ext/etc/build.prop" | cut -d'=' -f2)
    if [ -z "$input_android_target_version" ]; then
        echo "Error: ro.system_ext.build.version.release not found in build.prop" >&2
        exit 1
    fi
else
    echo "Error: build.prop file not found at ${pre_patch_file_dir}system_ext/etc/build.prop" >&2
    exit 1
fi

echo "📁 复制补丁模组源码..."
if [ ! -d "$workfile/mods" ]; then
    echo "❌ 补丁模组目录 $workfile/mods 不存在" >&2
    exit 1
fi
cp -a "$workfile/mods/." "$patch_mods_dir" || { echo "❌ 复制补丁模组源码失败" >&2; exit 1; }

echo "🛠️ 修补 miui-services.jar..."
if [ ! -f "${pre_patch_file_dir}system_ext/framework/miui-services.jar" ]; then
    echo "❌ miui-services.jar 不存在" >&2
    exit 1
fi
cp -f "${pre_patch_file_dir}system_ext/framework/miui-services.jar" "${patch_mods_dir}/miui-services-Smali/miui-services.jar" || { echo "❌ 复制 miui-services.jar 失败" >&2; exit 1; }
bash "${patch_mods_dir}/miui-services-Smali/run.sh" "$input_android_target_version" || { echo "❌ miui-services.jar 修补失败" >&2; exit 1; }

echo "🛠️ 修补 MiuiSystemUI.apk..."
if [ ! -f "${pre_patch_file_dir}system_ext/priv-app/MiuiSystemUI/MiuiSystemUI.apk" ]; then
    echo "❌ MiuiSystemUI.apk 不存在" >&2
    exit 1
fi
cp -f "${pre_patch_file_dir}system_ext/priv-app/MiuiSystemUI/MiuiSystemUI.apk" "${patch_mods_dir}/MiuiSystemUISmali/MiuiSystemUI.apk" || { echo "❌ 复制 MiuiSystemUI.apk 失败" >&2; exit 1; }
bash "${patch_mods_dir}/MiuiSystemUISmali/run.sh" "$input_android_target_version" || { echo "❌ MiuiSystemUI.apk 修补失败" >&2; exit 1; }

patched_files=(
    "miui-services-Smali/miui-services_out.jar"
    "MiuiSystemUISmali/MiuiSystemUI_out.apk"
)

echo "✅ 校验修补结果..."
for file in "${patched_files[@]}"; do
    if [ ! -f "${patch_mods_dir}${file}" ]; then
        echo "❌ 缺失补丁结果文件: ${file}" >&2
        exit 1
    fi
done

echo "📦 构建最终模块目录..."
if [ ! -d "$workfile/module_src" ]; then
    echo "❌ 模块源码目录 $workfile/module_src 不存在" >&2
    exit 1
fi
cp -a "$workfile/module_src/." "$release_dir" || { echo "❌ 复制模块源码失败" >&2; exit 1; }

mkdir -p "${release_dir}system/system_ext/framework/" || { echo "❌ 创建 framework 目录失败" >&2; exit 1; }
cp -f "${patch_mods_dir}miui-services-Smali/miui-services_out.jar" "${release_dir}system/system_ext/framework/miui-services.jar" || { echo "❌ 复制 miui-services_out.jar 失败" >&2; exit 1; }

mkdir -p "${release_dir}system/system_ext/priv-app/MiuiSystemUI/" || { echo "❌ 创建 MiuiSystemUI 目录失败" >&2; exit 1; }
cp -f "${patch_mods_dir}MiuiSystemUISmali/MiuiSystemUI_out.apk" "${release_dir}system/system_ext/priv-app/MiuiSystemUI/MiuiSystemUI.apk" || { echo "❌ 复制 MiuiSystemUI_out.apk 失败" >&2; exit 1; }

echo "📝 更新 module.prop 中的版本号..."
if [ ! -f "${release_dir}module.prop" ]; then
    echo "❌ module.prop 文件不存在" >&2
    exit 1
fi
sed -i "s/^version=.*/version=$(printf '%s' "$input_rom_version" | sed 's/[\/&]/\\&/g')/" "${release_dir}module.prop" || { echo "❌ 更新 module.prop 失败" >&2; exit 1; }

echo "📝 更新 system.prop 移除不兼容的配置"
if [ "$input_android_target_version" -eq 14 ]; then
    sed -i '/^ro\.config\.sothx_project_treble_support_vertical_screen_split/d' "${release_dir}system.prop" || { echo "❌ 更新 system.prop 失败" >&2; exit 1; }
    sed -i '/^ro\.config\.sothx_project_treble_vertical_screen_split_version/d' "${release_dir}system.prop" || { echo "❌ 更新 system.prop 失败" >&2; exit 1; }
fi
echo "version=$input_rom_version" >> $GITHUB_ENV
final_zip="${DistDir}${input_rom_version}.zip"
echo "📦 打包为 Magisk 模块：$final_zip"
cd "$release_dir" || { echo "❌ 无法切换到 $release_dir" >&2; exit 1; }
zip -r "$final_zip" ./* || { echo "❌ 打包 Magisk 模块失败" >&2; exit 1; }
cd "$workfile" || { echo "❌ 无法切换回 $workfile" >&2; exit 1; }

echo "✅ 构建完成：$final_zip"