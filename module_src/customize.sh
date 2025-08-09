# shellcheck disable=SC2148,SC2034,SC1091,SC2059
SKIPUNZIP=0
magisk_path=/data/adb/modules/
module_id=$(grep_prop id "$MODPATH/module.prop")

# 基础函数
add_props() {
  local line="$1"
  echo "$line" >>"$MODPATH/system.prop"
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

key_check() {
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "DOWN" ]]; then
      keycheck="$key_event"
      break
    fi
  done
  while true; do
    key_check=$(/system/bin/getevent -qlc 1)
    key_event=$(echo "$key_check" | awk '{ print $3 }' | grep 'KEY_')
    key_status=$(echo "$key_check" | awk '{ print $4 }')
    if [[ "$key_event" == *"KEY_"* && "$key_status" == "UP" ]]; then
      break
    fi
  done
}

# 版本检测前的内核环境检测（保留原逻辑）
if [[ "$KSU" == "true" ]]; then
  ui_print "- KernelSU 用户空间当前的版本号: $KSU_VER_CODE"
  ui_print "- KernelSU 内核空间当前的版本号: $KSU_KERNEL_VER_CODE"
  if [ "$KSU_VER_CODE" -lt 11551 ]; then
    ui_print "*********************************************"
    ui_print "- 请更新 KernelSU 到 v0.8.0+ ！"
    abort "*********************************************"
  fi
elif [[ "$APATCH" == "true" ]]; then
  ui_print "- APatch 当前的版本号: $APATCH_VER_CODE"
  ui_print "- APatch 当前的版本名: $APATCH_VER"
  ui_print "- KernelPatch 用户空间当前的版本号: $KERNELPATCH_VERSION"
  ui_print "- KernelPatch 内核空间当前的版本号: $KERNEL_VERSION"
  if [ "$APATCH_VER_CODE" -lt 10568 ]; then
    ui_print "*********************************************"
    ui_print "- 请更新 APatch 到 10568+ ！"
    abort "*********************************************"
  fi
else
  ui_print "- Magisk 版本: $MAGISK_VER_CODE"
fi

# 获取目标版本（来自 module.prop）
target_version=$(grep_prop version "$MODPATH/module.prop")

# 当前系统版本信息文件
prop_file="/mi_ext/etc/build.prop"

# 函数：询问用户是否强制安装，使用音量键
ask_force_install() {
  ui_print "- 是否强制安装模块？"
  ui_print "- [重要提醒]: 强制安装可能导致不兼容风险"
  ui_print "  音量+ ：是"
  ui_print "  音量- ：否"
  ui_print "*********************************************"

  key_check

  if [ "$keycheck" == "KEY_VOLUMEUP" ]; then
    ui_print "✔️ 已选择继续安装"
    return 0
  elif [ "$keycheck" == "KEY_VOLUMEDOWN" ]; then
    ui_print "❌ 安装已取消"
    abort "因用户取消而中止安装"
  else
    ui_print "❌ 未识别按键，安装已取消"
    abort "因未选择强制安装而中止安装"
  fi
}

# 尝试获取当前系统版本并判断
if [ -f "$prop_file" ]; then
  current_version=$(grep "^ro.mi.os.version.incremental=" "$prop_file" | cut -d'=' -f2)
  ui_print "- 当前系统版本: $current_version"
  ui_print "- 模块目标版本: $target_version"

  if [ "$current_version" = "$target_version" ]; then
    ui_print "✅ 系统版本匹配，继续安装..."
  else
    # 写入版本不匹配的属性，值为当前系统版本
    add_props "ro.config.sothx_cvw_full_module_version_mismatch=$current_version"

    ui_print "*********************************************"
    ui_print "⚠️ 系统版本不匹配：当前=$current_version，目标=$target_version"
    ui_print "- 当前系统版本与模块目标版本不符！"
    ui_print "- ⚠️ 安装可能导致开机卡死、闪退等严重问题"
    ui_print "- 如果正在使用**移植包**，且确认版本无误，可继续安装"
    ui_print "- 📛 请确保你已准备好Magisk救砖模块或救砖方式！"
    ask_force_install
  fi
else
  # 写入找不到系统版本文件的标记，值为true
  add_props "ro.config.sothx_cvw_full_module_version_missing=true"

  ui_print "*********************************************"
  ui_print "⚠️ 未找到系统版本文件：$prop_file"
  ui_print "- 系统版本信息缺失，环境不明，风险极高！"
  ui_print "- 📛 强烈建议不要安装此模块"
  ui_print "- 如果正在使用**移植包**，且能确认系统版本无误，可选择强制安装"
  ui_print "- ⚠️ 请注意：系统更新前必须卸载此模块，否则可能无法开机"
  ui_print "- 🚨 请提前准备Magisk救砖模块或其它救砖手段"
  ask_force_install
fi

ui_print "*********************************************"
ui_print "- 好诶w，模块已经安装完成了，重启设备后生效"
ui_print "- 如不生效请关闭[系统界面]的默认卸载行为或者给予root权限"
ui_print "*********************************************"
