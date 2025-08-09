#!/bin/bash
# shellcheck disable=SC2086
set -e

# 获取脚本所在目录（避免相对路径错误）
workfile="$(cd "$(dirname "$0")" && pwd)"
ExtractErofs="$workfile/common/binary/extract.erofs"
ExtractExt4="$workfile/common/binary/imgextractorLinux"
GetType="$workfile/common/binary/gettype"
PayloadExtract="$workfile/common/binary/payload_extract"
sudo chmod -R 777 "$workfile/common/binary/"

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

# 参数解析
while [[ $# -gt 0 ]]; do
  case "$1" in
  --rom)
    input_rom_version="$2"
    shift 2
    ;;
  --url)
    input_rom_url="$2"
    shift 2
    ;;
  *)
    echo "❌ 未知参数: $1"
    exit 1
    ;;
  esac
done

# 检查必须参数
if [[ -z "$input_rom_version" || -z "$input_rom_url" ]]; then
  echo "❌ 错误：必须提供 --rom 和 --url 参数。" >&2
  echo "用法：bash ./$0 --rom <ROM_VERSION> --url <ROM_URL>" >&2
  exit 1
fi

echo "🧹 清理并准备临时目录..."
sudo rm -rf "$TMPDir"
mkdir -p "$TMPDir" "$DistDir" "$payload_img_dir" "$pre_patch_file_dir" "$patch_mods_dir" "$release_dir"

echo "⬇️ 获取 system_ext.img..."
# 本地测试用例，使用时需修改 TARGET_ZIP_NAME 值并放置 ROM 包 ，同时 **取消注释下面两条语句** 和 **注释原来的 PayloadExtract 语句**
# TARGET_ZIP_NAME="sheng-ota_full-OS2.0.205.0.VNXCNXM-user-15.0-ff1ab1912a.zip"
# $PayloadExtract -i "$TARGET_ZIP_NAME" -t zip -o "$payload_img_dir" -X system_ext
$PayloadExtract -i "$input_rom_url" -t url -o "$payload_img_dir" -X system_ext

if [ ! -f "${payload_img_dir}system_ext.img" ]; then
  echo "❌ 找不到 system_ext.img" >&2
  exit 1
fi

# 根据镜像格式选择工具
img_type=$("$GetType" -i "${payload_img_dir}system_ext.img")
if [[ "$img_type" == "erofs" ]]; then
  echo "📦 使用 extract.erofs 解包 system_ext.img..."
  "$ExtractErofs" \
    -i "${payload_img_dir}system_ext.img" \
    -x -c "$workfile/common/system_ext_unpak_list.txt" \
    -o "$pre_patch_file_dir"
elif [[ "$img_type" == "ext" ]]; then
  echo "📦 使用 imgextractorLinux 解包 system_ext.img..."
  sudo "$ExtractExt4" "${payload_img_dir}system_ext.img" "$pre_patch_file_dir"
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
done <"$system_ext_unpak_list_file"

if [[ "$img_type" == "ext" ]]; then
  mkdir -p $workfile/tmp_ext4/system_ext/framework $workfile/tmp_ext4/system_ext/priv-app/MiuiSystemUI $workfile/tmp_ext4/system_ext/etc
  sudo cp -rf ${pre_patch_file_dir}system_ext/framework/miui-services.jar $workfile/tmp_ext4/system_ext/framework
  sudo cp -rf ${pre_patch_file_dir}system_ext/priv-app/MiuiSystemUI/MiuiSystemUI.apk $workfile/tmp_ext4/system_ext/priv-app/MiuiSystemUI
  sudo cp -rf ${pre_patch_file_dir}system_ext/etc/build.prop $workfile/tmp_ext4/system_ext/etc
  sudo rm -rf ${pre_patch_file_dir}system_ext/*
  sudo cp -rf $workfile/tmp_ext4/system_ext/* ${pre_patch_file_dir}system_ext/
  sudo rm -rf $workfile/tmp_ext4
fi
sudo chmod -R 777 ${pre_patch_file_dir}system_ext

input_android_target_version=$(grep ro.system_ext.build.version.release= ${pre_patch_file_dir}system_ext/etc/build.prop | cut -d'=' -f2)
rm -rf ${pre_patch_file_dir}system_ext/etc

# 校验 Android 版本，目前仅支持 14 和 15，保留未来扩展空间
case "$input_android_target_version" in
14 | 15)
  # 支持的版本，继续执行
  ;;
*)
  echo "❌ 错误：不支持的 Android 版本：$input_android_target_version，仅支持 14 或 15。" >&2
  exit 1
  ;;
esac

echo "📁 复制补丁模组源码..."
cp -a "$workfile/mods/." "$patch_mods_dir"

echo "🛠️ 修补 miui-services.jar..."
cp -f "${pre_patch_file_dir}system_ext/framework/miui-services.jar" "${patch_mods_dir}/miui-services-Smali/miui-services.jar"
bash "${patch_mods_dir}/miui-services-Smali/run.sh" "$input_android_target_version"

echo "🛠️ 修补 MiuiSystemUI.apk..."
cp -f "${pre_patch_file_dir}system_ext/priv-app/MiuiSystemUI/MiuiSystemUI.apk" "${patch_mods_dir}/MiuiSystemUISmali/MiuiSystemUI.apk"
bash "${patch_mods_dir}/MiuiSystemUISmali/run.sh" "$input_android_target_version"

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
cp -a "$workfile/module_src/." "$release_dir"

mkdir -p "${release_dir}system/system_ext/framework/"
cp -f "${patch_mods_dir}miui-services-Smali/miui-services_out.jar" "${release_dir}system/system_ext/framework/miui-services.jar"

mkdir -p "${release_dir}system/system_ext/priv-app/MiuiSystemUI/"
cp -f "${patch_mods_dir}MiuiSystemUISmali/MiuiSystemUI_out.apk" "${release_dir}system/system_ext/priv-app/MiuiSystemUI/MiuiSystemUI.apk"

echo "📝 更新 module.prop 中的版本号..."
sed -i "s/^version=.*/version=${input_rom_version}/" "${release_dir}module.prop"

echo "📝 更新 system.prop 移除不兼容的配置"
if [ "$input_android_target_version" -eq 14 ]; then
  sed -i '/^ro\.config\.sothx_project_treble_support_vertical_screen_split/d' "${release_dir}system.prop"
  sed -i '/^ro\.config\.sothx_project_treble_vertical_screen_split_version/d' "${release_dir}system.prop"
fi

final_zip="${DistDir}${input_rom_version}.zip"
echo "📦 打包为 Magisk 模块：$final_zip"
cd "$release_dir"
zip -r "$final_zip" ./*
cd "$workfile"

echo "✅ 构建完成：$final_zip"
