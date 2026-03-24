#!/bin/bash
# shellcheck disable=SC2003,SC2046,SC2086,SC2162,SC2154,SC2155
android_target_version="$1"
workfile=${0%/*}
APKEditor="java -jar $workfile/../../../common/jar/APKEditor.jar"
$APKEditor d -f -i "$workfile/MiuiSystemUI.apk" -o "$workfile/MiuiSystemUI" > /dev/null 2>&1



patch_VerticalSplit() {
    ### 竖屏上下分屏
    # 查找原函数位置
    local SplitScreenUtilsSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/common/split -type f -iname "SplitScreenUtils.smali")
    local start_line_isLeftRightSplitForZ=$(grep -n -m 1 ".method public static isLeftRightSplit(ZLandroid/content/res/Configuration;)Z" "$SplitScreenUtilsSmali" | cut -d: -f1)

    # 在start_line_isLeftRightSplitForZ的上一行插入新方法
    local insert_line_getVerticalSplitValue=$((start_line_isLeftRightSplitForZ - 1))
    sed -i "${insert_line_getVerticalSplitValue}r $workfile/getVerticalSplitValue.smali" "$SplitScreenUtilsSmali"

    # 从start_line_isLeftRightSplitForZ开始查找 "const/16 v1, 0x258"
    local start_line_isLeftRightSplitForZ=$(grep -n -m 1 ".method public static isLeftRightSplit(ZLandroid/content/res/Configuration;)Z" "$SplitScreenUtilsSmali" | cut -d: -f1)
    local find_line_isLeftRightSplitForZ_relative_v1_const=$(tail -n +"$start_line_isLeftRightSplitForZ" "$SplitScreenUtilsSmali" | grep -n -m 1 "const/16 v1, 0x258" | cut -d: -f1)
    local end_line_isLeftRightSplitForZ_v1_const=$((start_line_isLeftRightSplitForZ + find_line_isLeftRightSplitForZ_relative_v1_const - 1))

    # 删除end_line那一行
    sed -i "${end_line_isLeftRightSplitForZ_v1_const}d" "$SplitScreenUtilsSmali"
    # 在end_line原来的位置插入Insert_getVerticalSplitValue_Func.smali
    sed -i "${end_line_isLeftRightSplitForZ_v1_const}r $workfile/Insert_getVerticalSplitValue_Func.smali" "$SplitScreenUtilsSmali"

    echo '修补verticalSplit完成'
}

patch_VerticalSplitEntry() {
  # 如果系统版本 >= 16，表示原生已支持，跳过 patch
  if [ "$android_target_version" -ge 16 ]; then
    echo "✅ Android $android_target_version 已支持 vertical split，无需 patch"
    return 0
  fi

  case "$android_target_version" in
    15)
      patch_VerticalSplit
      ;;
    14)
      echo "⚠️ Android 14 未适配 vertical split patch，跳过"
      ;;
    *)
      echo "❌ Unsupported Android version for vertical split patch: $android_target_version"
      exit 1
      ;;
  esac
}

patch_A14_CvwFull() {
    
    local MiuiInfinityModeSizeLevelConfigSmali=$(find $workfile MiuiSystemUI/smali/*/com/android/wm/shell/miuifreeform -type f -iname "MiuiInfinityModeSizeLevelConfig.smali")
    if [ -z "$MiuiInfinityModeSizeLevelConfigSmali" ]; then
      echo "❌ 未找到 MiuiInfinityModeSizeLevelConfig.smali"
      exit 1
    fi

    local getLevelTypeForStringFuncType='private'

    local getLevelTypeForString_start_line=$(grep -n -m 1 ".method private getLevelType(Ljava/lang/String;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    
    if [[ -z "$getLevelTypeForString_start_line" ]]; then
      getLevelTypeForStringFuncType='public'
      getLevelTypeForString_start_line=$(grep -n -m 1 ".method public getLevelType(Ljava/lang/String;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    fi

    echo "getLevelTypeForString_start_line=$getLevelTypeForString_start_line"

    # 在getLevelTypeForString_start_line的上一行插入新方法-getCvwFull_Func
    local insert_getCvwFull_Func_line_to_MiuiInfinityModeSizeLevelConfigSmali=$((getLevelTypeForString_start_line - 1))
    echo "insert_getCvwFull_Func_line_to_MiuiInfinityModeSizeLevelConfigSmali=$insert_getCvwFull_Func_line_to_MiuiInfinityModeSizeLevelConfigSmali"
    sed -i "${insert_getCvwFull_Func_line_to_MiuiInfinityModeSizeLevelConfigSmali}r $workfile/getCvwFull_Func.smali" "$MiuiInfinityModeSizeLevelConfigSmali"
 
 
    # 重新查找getLevelTypeForString_start_line
    getLevelTypeForString_start_line=$(grep -n -m 1 ".method private getLevelType(Ljava/lang/String;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    if [[ -z "$getLevelTypeForString_start_line" ]]; then
      getLevelTypeForStringFuncType='public'
      getLevelTypeForString_start_line=$(grep -n -m 1 ".method public getLevelType(Ljava/lang/String;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    fi
    echo "getLevelTypeForString_start_line=$getLevelTypeForString_start_line"
    
    # 从getLevelTypeForString_start_line开始查找第一个.end method行号
    local getLevelTypeForString_end_line=$(tail -n +"$getLevelTypeForString_start_line" $MiuiInfinityModeSizeLevelConfigSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    # 计算.end method的行号
    local actual_getLevelTypeForString_end_line=$((getLevelTypeForString_start_line + getLevelTypeForString_end_line - 1))
    echo "actual_getLevelTypeForString_end_line=$actual_getLevelTypeForString_end_line"
    # 删除原方法
    sed -i "${getLevelTypeForString_start_line},${actual_getLevelTypeForString_end_line}d" $MiuiInfinityModeSizeLevelConfigSmali
    # 插入Patch后的方法
    if [[ $getLevelTypeForStringFuncType = 'private' ]];then
    sed -i "$((getLevelTypeForString_start_line - 1))r $workfile/$android_target_version/getLevelTypeForStringPrivate.smali" "$MiuiInfinityModeSizeLevelConfigSmali"
    else
    sed -i "$((getLevelTypeForString_start_line - 1))r $workfile/$android_target_version/getLevelTypeForStringPublic.smali" "$MiuiInfinityModeSizeLevelConfigSmali"
    fi

    # 重新查找getLevelTypeForComponentName_start_line
    local getLevelTypeForComponentName_start_line=$(grep -n -m 1 ".method public getLevelType(Landroid/content/ComponentName;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    echo "getLevelTypeForComponentName_start_line=$getLevelTypeForComponentName_start_line"
    # 从getLevelTypeForComponentName_start_line开始查找第一个.end method行号
    local getLevelTypeForComponentName_end_line=$(tail -n +"$getLevelTypeForComponentName_start_line" $MiuiInfinityModeSizeLevelConfigSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    echo "getLevelTypeForComponentName_end_line=$getLevelTypeForComponentName_end_line"
    # 计算.end method的行号
    local actual_getLevelTypeForComponentName_end_line=$((getLevelTypeForComponentName_start_line + getLevelTypeForComponentName_end_line - 1))
   echo "actual_getLevelTypeForComponentName_end_line=$actual_getLevelTypeForComponentName_end_line"
    # 删除原方法
    sed -i "${getLevelTypeForComponentName_start_line},${actual_getLevelTypeForComponentName_end_line}d" $MiuiInfinityModeSizeLevelConfigSmali
    # 插入Patch后的方法
    if [[ $getLevelTypeForStringFuncType = 'private' ]];then
    sed -i "$((getLevelTypeForComponentName_start_line - 1))r $workfile/$android_target_version/getLevelTypeForComponentNameByPrivate.smali" $MiuiInfinityModeSizeLevelConfigSmali
    else
    sed -i "$((getLevelTypeForComponentName_start_line - 1))r $workfile/$android_target_version/getLevelTypeForComponentNameByPublic.smali" $MiuiInfinityModeSizeLevelConfigSmali
    fi

    local MiuiInfinityModeLevelPolicyCompatSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/miuifreeform/infinitymode -type f -iname "MiuiInfinityModeLevelPolicyCompat.smali")

    if [ -z "$MiuiInfinityModeLevelPolicyCompatSmali" ]; then
      echo "❌ 未找到 MiuiInfinityModeLevelPolicyCompat.smali"
      exit 1
    fi

    local useNewLevelPolicyForString_start_line=$(grep -n -m 1 ".method public useNewLevelPolicy(Ljava/lang/String;)Z" "$MiuiInfinityModeLevelPolicyCompatSmali" | cut -d: -f1)
    echo "useNewLevelPolicyForString_start_line=$useNewLevelPolicyForString_start_line"
    
    # 在useNewLevelPolicyForString_start_line的上一行插入新方法-getCvwFull_Func
    local insert_getCvwFull_Func_line_to_MiuiInfinityModeLevelPolicyCompatSmali=$((useNewLevelPolicyForString_start_line - 1))
    echo "insert_getCvwFull_Func_line_to_MiuiInfinityModeLevelPolicyCompatSmali=$insert_getCvwFull_Func_line_to_MiuiInfinityModeLevelPolicyCompatSmali"
    sed -i "${insert_getCvwFull_Func_line_to_MiuiInfinityModeLevelPolicyCompatSmali}r $workfile/getCvwFull_Func.smali" "$MiuiInfinityModeLevelPolicyCompatSmali"

    # 重新查找useNewLevelPolicyForString_start_line
    useNewLevelPolicyForString_start_line=$(grep -n -m 1 ".method public useNewLevelPolicy(Ljava/lang/String;)Z" "$MiuiInfinityModeLevelPolicyCompatSmali" | cut -d: -f1)
    echo "useNewLevelPolicyForString_start_line=$useNewLevelPolicyForString_start_line"
    # 从useNewLevelPolicyForString_start_line开始查找第一个.end method行号
    local useNewLevelPolicyForString_end_line=$(tail -n +"$useNewLevelPolicyForString_start_line" $MiuiInfinityModeLevelPolicyCompatSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    echo "useNewLevelPolicyForString_end_line=$useNewLevelPolicyForString_end_line"
    # 计算.end method的行号
    local actual_useNewLevelPolicyForString_end_line=$((useNewLevelPolicyForString_start_line + useNewLevelPolicyForString_end_line - 1))
    echo "actual_useNewLevelPolicyForString_end_line=$actual_useNewLevelPolicyForString_end_line"
    # 删除原方法
    sed -i "${useNewLevelPolicyForString_start_line},${actual_useNewLevelPolicyForString_end_line}d" $MiuiInfinityModeLevelPolicyCompatSmali
    # 插入Patch后的方法
    sed -i "$((useNewLevelPolicyForString_start_line - 1))r $workfile/$android_target_version/useNewLevelPolicyForString.smali" $MiuiInfinityModeLevelPolicyCompatSmali

    echo '修补CvwFull完成'
}

### 所有应用支持无极小窗
patch_CvwFull() {

    local MiuiInfinityModeSizeLevelConfigSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/multitasking/miuiinfinitymode -type f -iname "MiuiInfinityModeSizeLevelConfig.smali")

    if [ -z "$MiuiInfinityModeSizeLevelConfigSmali" ]; then
      echo "❌ 未找到 MiuiInfinityModeSizeLevelConfig.smali"
      exit 1
    fi
    
    local getLevelTypeForString_start_line=$(grep -n -m 1 ".method public getLevelType(Ljava/lang/String;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    # 在getLevelTypeForString_start_line的上一行插入新方法-getCvwFull_Func
    local insert_getCvwFull_Func_line_to_MiuiInfinityModeSizeLevelConfigSmali=$((getLevelTypeForString_start_line - 1))
    sed -i "${insert_getCvwFull_Func_line_to_MiuiInfinityModeSizeLevelConfigSmali}r $workfile/getCvwFull_Func.smali" "$MiuiInfinityModeSizeLevelConfigSmali"

    # 重新查找getLevelTypeForString_start_line
    local getLevelTypeForString_start_line=$(grep -n -m 1 ".method public getLevelType(Ljava/lang/String;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    # 从getLevelTypeForString_start_line开始查找第一个.end method行号
    local getLevelTypeForString_end_line=$(tail -n +"$getLevelTypeForString_start_line" $MiuiInfinityModeSizeLevelConfigSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    # 计算.end method的行号
    local actual_getLevelTypeForString_end_line=$((getLevelTypeForString_start_line + getLevelTypeForString_end_line - 1))
    # 删除原方法
    sed -i "${getLevelTypeForString_start_line},${actual_getLevelTypeForString_end_line}d" $MiuiInfinityModeSizeLevelConfigSmali
    # 插入Patch后的方法
    sed -i "$((getLevelTypeForString_start_line - 1))r $workfile/$android_target_version/getLevelTypeForString.smali" $MiuiInfinityModeSizeLevelConfigSmali

    # 重新查找getLevelTypeForComponentName_start_line
    local getLevelTypeForComponentName_start_line=$(grep -n -m 1 ".method public getLevelType(Landroid/content/ComponentName;)I" "$MiuiInfinityModeSizeLevelConfigSmali" | cut -d: -f1)
    # 从getLevelTypeForComponentName_start_line开始查找第一个.end method行号
    local getLevelTypeForComponentName_end_line=$(tail -n +"$getLevelTypeForComponentName_start_line" $MiuiInfinityModeSizeLevelConfigSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    # 计算.end method的行号
    local actual_getLevelTypeForComponentName_end_line=$((getLevelTypeForComponentName_start_line + getLevelTypeForComponentName_end_line - 1))
    # 删除原方法
    sed -i "${getLevelTypeForComponentName_start_line},${actual_getLevelTypeForComponentName_end_line}d" $MiuiInfinityModeSizeLevelConfigSmali
    # 插入Patch后的方法
    sed -i "$((getLevelTypeForComponentName_start_line - 1))r $workfile/$android_target_version/getLevelTypeForComponentName.smali" $MiuiInfinityModeSizeLevelConfigSmali

    local MiuiInfinityModeLevelPolicyCompatSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/multitasking/miuiinfinitymode -type f -iname "MiuiInfinityModeLevelPolicyCompat.smali")

    if [ -z "$MiuiInfinityModeLevelPolicyCompatSmali" ]; then
      echo "❌ 未找到 MiuiInfinityModeLevelPolicyCompat.smali"
      exit 1
    fi

    local useNewLevelPolicyForString_start_line=$(grep -n -m 1 ".method public useNewLevelPolicy(Ljava/lang/String;)Z" "$MiuiInfinityModeLevelPolicyCompatSmali" | cut -d: -f1)
    # 在useNewLevelPolicyForString_start_line的上一行插入新方法-getCvwFull_Func
    local insert_getCvwFull_Func_line_to_MiuiInfinityModeLevelPolicyCompatSmali=$((useNewLevelPolicyForString_start_line - 1))
    sed -i "${insert_getCvwFull_Func_line_to_MiuiInfinityModeLevelPolicyCompatSmali}r $workfile/getCvwFull_Func.smali" "$MiuiInfinityModeLevelPolicyCompatSmali"

    # 重新查找useNewLevelPolicyForString_start_line
    local useNewLevelPolicyForString_start_line=$(grep -n -m 1 ".method public useNewLevelPolicy(Ljava/lang/String;)Z" "$MiuiInfinityModeLevelPolicyCompatSmali" | cut -d: -f1)
    # 从useNewLevelPolicyForString_start_line开始查找第一个.end method行号
    local useNewLevelPolicyForString_end_line=$(tail -n +"$useNewLevelPolicyForString_start_line" $MiuiInfinityModeLevelPolicyCompatSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    # 计算.end method的行号
    local actual_useNewLevelPolicyForString_end_line=$((useNewLevelPolicyForString_start_line + useNewLevelPolicyForString_end_line - 1))
    # 删除原方法
    sed -i "${useNewLevelPolicyForString_start_line},${actual_useNewLevelPolicyForString_end_line}d" $MiuiInfinityModeLevelPolicyCompatSmali
    # 插入Patch后的方法
    sed -i "$((useNewLevelPolicyForString_start_line - 1))r $workfile/$android_target_version/useNewLevelPolicyForString.smali" $MiuiInfinityModeLevelPolicyCompatSmali

    echo '修补CvwFull完成'
}

patch_CvwFullEntry() {
  if [ "$android_target_version" -ge 15 ]; then
    patch_CvwFull
  elif [ "$android_target_version" -eq 14 ]; then
    patch_A14_CvwFull
  else
    echo "❌ Unsupported Android version for disable freeform bottom caption patch: $android_target_version"
    exit 1
  fi
}


### 隐藏自由窗口小白条
patch_A14_DisableFreeformBottomCaption() {

    local MiuiBaseWindowDecorationSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/miuimultiwinswitch/miuiwindowdecor -type f -iname "MiuiBaseWindowDecoration.smali")
    if [ -z "$MiuiBaseWindowDecorationSmali" ]; then
      echo "❌ 未找到 MiuiBaseWindowDecoration.smali"
      exit 1
    fi
    # 查找createBottomCaption_start_line
    local createBottomCaption_start_line=$(grep -n -m 1 ".method private createBottomCaption()Lcom/android/wm/shell/miuimultiwinswitch/miuiwindowdecor/MiuiBottomBarView;" "$MiuiBaseWindowDecorationSmali" | cut -d: -f1)
    echo "createBottomCaption_start_line=$createBottomCaption_start_line"
    # 从createBottomCaption_start_line开始查找第一个.end method行号
    local createBottomCaption_end_line=$(tail -n +"$createBottomCaption_start_line" $MiuiBaseWindowDecorationSmali | grep -n -m 1 "new-instance v0, Lcom/android/wm/shell/miuimultiwinswitch/miuiwindowdecor/MiuiBottomBarView;" | cut -d: -f1)
    echo "createBottomCaption_end_line=$createBottomCaption_end_line"
    # 计算.end method的行号
    local actual_createBottomCaption_end_line=$((createBottomCaption_start_line + createBottomCaption_end_line - 1))
    echo "createBottomCaption_end_line=$createBottomCaption_end_line"
    # 删除原方法
    sed -i "${createBottomCaption_start_line},${actual_createBottomCaption_end_line}d" $MiuiBaseWindowDecorationSmali
    # 插入Patch后的方法
    sed -i "$((createBottomCaption_start_line - 1))r $workfile/$android_target_version/createBottomCaption.smali" $MiuiBaseWindowDecorationSmali

    echo '修补隐藏自由窗口小白条完成'
}

patch_A15_DisableFreeformBottomCaption() {

    local MiuiBottomDecorationSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/multitasking/miuimultiwinswitch/miuiwindowdecor -type f -iname "MiuiBottomDecoration.smali")
    if [ -z "$MiuiBottomDecorationSmali" ]; then
      echo "❌ 未找到 MiuiBottomDecoration.smali"
      exit 1
    fi
    # 查找createBottomCaption_start_line
    local createBottomCaption_start_line=$(grep -n -m 1 ".method private createBottomCaption()Lcom/android/wm/shell/multitasking/miuimultiwinswitch/miuiwindowdecor/MiuiBottomBarView;" "$MiuiBottomDecorationSmali" | cut -d: -f1)
    echo "createBottomCaption_start_line=$createBottomCaption_start_line"
    # 从createBottomCaption_start_line开始查找第一个.end method行号
    local createBottomCaption_end_line=$(tail -n +"$createBottomCaption_start_line" $MiuiBottomDecorationSmali | grep -n -m 1 "new-instance v0, Lcom/android/wm/shell/multitasking/miuimultiwinswitch/miuiwindowdecor/MiuiBottomBarView;" | cut -d: -f1)
    echo "createBottomCaption_end_line=$createBottomCaption_end_line"
    # 计算.end method的行号
    local actual_createBottomCaption_end_line=$((createBottomCaption_start_line + createBottomCaption_end_line - 1))
    echo "actual_createBottomCaption_end_line=$actual_createBottomCaption_end_line"
    # 删除原方法
    sed -i "${createBottomCaption_start_line},${actual_createBottomCaption_end_line}d" $MiuiBottomDecorationSmali
    # 插入Patch后的方法
    sed -i "$((createBottomCaption_start_line - 1))r $workfile/$android_target_version/createBottomCaption.smali" $MiuiBottomDecorationSmali

    echo '修补隐藏自由窗口小白条完成'
}

patch_DisableFreeformBottomCaption() {

    local MiuiBottomDecorationSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/multitasking/miuimultiwinswitch/miuiwindowdecor/decoration -type f -iname "MiuiDecorationBottomViewHost.smali")
    if [ -z "$MiuiBottomDecorationSmali" ]; then
      echo "❌ 未找到 MiuiBottomDecoration.smali"
      exit 1
    fi
    # 查找createBottomCaption_start_line
    local createBottomCaption_start_line=$(grep -n -m 1 ".method public createBottomCaption()Lcom/android/wm/shell/multitasking/miuimultiwinswitch/miuiwindowdecor/decoration/MiuiDecorationBottomView;" "$MiuiBottomDecorationSmali" | cut -d: -f1)
    echo "createBottomCaption_start_line=$createBottomCaption_start_line"
    # 从createBottomCaption_start_line开始查找第一个.end method行号
    local createBottomCaption_end_line=$(tail -n +"$createBottomCaption_start_line" $MiuiBottomDecorationSmali | grep -n -m 1 "invoke-virtual {p0}, Lcom/android/wm/shell/multitasking/miuimultiwinswitch/miuiwindowdecor/decoration/MiuiDecorationBottomViewHost;->getSurfaceHeight()F" | cut -d: -f1)
    echo "createBottomCaption_end_line=$createBottomCaption_end_line"
    # 计算.end method的行号
    local actual_createBottomCaption_end_line=$((createBottomCaption_start_line + createBottomCaption_end_line - 1))
    echo "actual_createBottomCaption_end_line=$actual_createBottomCaption_end_line"
    # 删除原方法
    sed -i "${createBottomCaption_start_line},${actual_createBottomCaption_end_line}d" $MiuiBottomDecorationSmali
    # 插入Patch后的方法
    sed -i "$((createBottomCaption_start_line - 1))r $workfile/$android_target_version/createBottomCaption.smali" $MiuiBottomDecorationSmali

    echo '修补隐藏自由窗口小白条完成'
}

patch_DisableFreeformBottomCaptionEntry() {
    # 如果系统版本 >= 16，跳过 patch
  if [ "$android_target_version" -ge 16 ]; then
    return 0
  fi
  if [ "$android_target_version" -ge 16 ]; then
    patch_DisableFreeformBottomCaption
  elif [ "$android_target_version" -eq 15 ]; then
    patch_A15_DisableFreeformBottomCaption
  elif [ "$android_target_version" -eq 14 ]; then
    patch_A14_DisableFreeformBottomCaption
  else
    echo "❌ Unsupported Android version for disable freeform bottom caption patch: $android_target_version"
    exit 1
  fi
}


### 自定义窗口控制器黑名单(A14)
patch_A14_CustomDotBlackList() {

    local MiuiMultiWinSwitchConfigSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/miuimultiwinswitch -type f -iname "MiuiMultiWinSwitchConfig.smali")
    
    # 查找getDotBlackList_start_line
    local getDotBlackList_start_line=$(grep -n -m 1 ".method public getDotBlackList()Ljava/util/Set;" "$MiuiMultiWinSwitchConfigSmali" | cut -d: -f1)
    echo "getDotBlackList_start_line=$getDotBlackList_start_line"
    # 从getDotBlackList_start_line开始查找第一个.end method行号
    local getDotBlackList_end_line=$(tail -n +"$getDotBlackList_start_line" $MiuiMultiWinSwitchConfigSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    echo "getDotBlackList_end_line=$getDotBlackList_end_line"
    # 计算.end method的行号
    local actual_getDotBlackList_end_line=$((getDotBlackList_start_line + getDotBlackList_end_line - 1))
    echo "actual_getDotBlackList_end_line=$actual_getDotBlackList_end_line"
    # 删除原方法
    sed -i "${getDotBlackList_start_line},${actual_getDotBlackList_end_line}d" $MiuiMultiWinSwitchConfigSmali
    # 插入Patch后的方法
    sed -i "$((getDotBlackList_start_line - 1))r $workfile/$android_target_version/customDotBlackList.smali" $MiuiMultiWinSwitchConfigSmali

    echo '修补自定义窗口控制器黑名单完成'
}

### 自定义窗口控制器黑名单
patch_CustomDotBlackList() {

    local MulWinSwitchConfigSmali=$(find $workfile/MiuiSystemUI/smali/*/com/android/wm/shell/multitasking/miuimultiwinswitch -type f -iname "MulWinSwitchConfig.smali")
    
    # 查找getDotBlackList_start_line
    local getDotBlackList_start_line=$(grep -n -m 1 ".method public getDotBlackList()Ljava/util/Set;" "$MulWinSwitchConfigSmali" | cut -d: -f1)
    echo "getDotBlackList_start_line=$getDotBlackList_start_line"
    # 从createBottomCaption_start_line开始查找第一个.end method行号
    local getDotBlackList_end_line=$(tail -n +"$getDotBlackList_start_line" $MulWinSwitchConfigSmali | grep -n -m 1 ".end method" | cut -d: -f1)
    echo "getDotBlackList_end_line=$getDotBlackList_end_line"
    # 计算.end method的行号
    local actual_getDotBlackList_end_line=$((getDotBlackList_start_line + getDotBlackList_end_line - 1))
    echo "actual_getDotBlackList_end_line=$actual_getDotBlackList_end_line"
    # 删除原方法
    sed -i "${getDotBlackList_start_line},${actual_getDotBlackList_end_line}d" $MulWinSwitchConfigSmali
    # 插入Patch后的方法
    sed -i "$((getDotBlackList_start_line - 1))r $workfile/customDotBlackList.smali" $MulWinSwitchConfigSmali

    echo '修补自定义窗口控制器黑名单完成'
}

patch_CustomDotBlackListEntry() {
  if [ "$android_target_version" -ge 15 ]; then
    patch_CustomDotBlackList
  elif [ "$android_target_version" -eq 14 ]; then
    patch_A14_CustomDotBlackList
  else
    echo "❌ Unsupported Android version for custom dot black list patch: $android_target_version"
    exit 1
  fi
}



### 运行修补
# patch_VerticalSplitEntry
patch_CvwFullEntry
patch_DisableFreeformBottomCaptionEntry
patch_CustomDotBlackListEntry

### 兼容小米错误的资源数据-@style/null
sed -i 's/\s*parent="@style\/null"//g' $workfile/MiuiSystemUI/resources/*/res/values/styles.xml
sed -i 's/\s*parent="@style\/null"//g' $workfile/MiuiSystemUI/resources/*/res/values-night/styles.xml

$APKEditor b -f -i $workfile/MiuiSystemUI -o $workfile/MiuiSystemUI_out.apk > /dev/null 2>&1
