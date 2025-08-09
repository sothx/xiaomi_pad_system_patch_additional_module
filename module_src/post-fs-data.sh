# shellcheck disable=SC2148,SC1091
MODDIR=${0%/*}

prop_file="/mi_ext/etc/build.prop"
module_prop="$MODDIR/module.prop"
log_file="$MODDIR/log.txt"

# 每次运行前清除旧日志
rm -f "$log_file"

# 写入日志
log_reason() {
    echo "[$(date +%s)] $1" >>"$log_file"
}

# 禁用模块并记录原因
disable_module() {
    log_reason "$1"
    touch "$MODDIR/disable"
    exit 1
}

# 读取模块要求的目标版本
target_version=$(grep "^version=" "$module_prop" | cut -d'=' -f2)
[ -n "$target_version" ] || disable_module "❌ 无法获取模块目标版本（module.prop 缺失或格式错误）"

# 读取 system.prop 标记
mismatch_version=$(grep "^ro.config.sothx_cvw_full_module_version_mismatch=" "$MODDIR/system.prop" | cut -d'=' -f2)
version_missing_flag=$(grep "^ro.config.sothx_cvw_full_module_version_missing=" "$MODDIR/system.prop" | cut -d'=' -f2)

# 如果存在版本缺失标记，则跳过所有校验
if [ "$version_missing_flag" = "true" ]; then
    log_reason "⚠️ 系统版本文件缺失标记存在，模块继续启用"
    exit 0
fi

# 获取当前系统版本
if [ -f "$prop_file" ]; then
    current_version=$(grep "^ro.mi.os.version.incremental=" "$prop_file" | cut -d'=' -f2)
else
    log_reason "❌ 系统版本文件不存在：$prop_file"
    current_version=""
fi

# 校验当前系统版本是否为空
[ -n "$current_version" ] || disable_module "❌ 当前系统版本为空，无法比对"

# 如果存在 mismatch_version，用作替代的 target_version
if [ -n "$mismatch_version" ]; then
    log_reason "⚠️ 使用 mismatch 标记版本作为目标版本: $mismatch_version"
    target_version="$mismatch_version"
fi

# 比对版本
if [ "$current_version" != "$target_version" ]; then
    disable_module "❌ 系统版本不匹配：当前版本=$current_version，目标版本=$target_version"
fi

# 匹配成功
log_reason "✅ 版本匹配成功，模块启用：$current_version"
exit 0
