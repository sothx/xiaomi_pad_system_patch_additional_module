# ✨ 小米平板系统体验增强附加模块 · 自动构建

适用于小米平板的 **系统体验功能增强的 Magisk 模块**，提取 ROM 自动生成模块文件，提供部分系统体验增强功能。

当前支持 **Android 14 和 Android 15** 的 Hyper OS For Pad。

---

## 📚 文档目录

- [✨ 小米平板系统体验增强附加模块 · 自动构建](#-小米平板系统体验增强附加模块--自动构建)
  - [📚 文档目录](#-文档目录)
  - [💡 模块功能说明](#-模块功能说明)
  - [⚠️ 使用须知：系统更新前请注意！](#️-使用须知系统更新前请注意)
  - [📱 当前支持系统版本](#-当前支持系统版本)
  - [🚀 快速开始：构建你的专属模块](#-快速开始构建你的专属模块)
    - [1️⃣ Fork 本项目](#1️⃣-fork-本项目)
    - [2️⃣ 打开 Actions 页面](#2️⃣-打开-actions-页面)
    - [3️⃣ 填写构建参数，运行 workflow](#3️⃣-填写构建参数运行-workflow)
    - [4️⃣ 下载模块](#4️⃣-下载模块)
  - [📁 模块使用说明](#-模块使用说明)
  - [❓ 常见问题](#-常见问题)
  - [🔄 Fork 用户同步更新](#-fork-用户同步更新)
    - [✅ 方法一：GitHub 网页操作（适合不熟悉 Git 的用户）](#-方法一github-网页操作适合不熟悉-git-的用户)
    - [🧑‍💻 方法二：命令行同步（适合开发者）](#-方法二命令行同步适合开发者)
  - [🔧 移植包适配说明（供移植包作者参考）](#-移植包适配说明供移植包作者参考)
    - [1️⃣ 正确配置 `/product/etc/dot_black_list.json` 权限](#1️⃣-正确配置-productetcdot_black_listjson-权限)
    - [2️⃣ 所有 system.prop 属性应写入 `/product/etc/build.prop`](#2️⃣-所有-systemprop-属性应写入-productetcbuildprop)
  - [🤝 贡献者](#-贡献者)
  - [🛠 技术说明](#-技术说明)

---

## 💡 模块功能说明

本模块适用于小米平板，提供以下系统增强功能：

| 功能               | 说明                                   |
| ------------------ | -------------------------------------- |
| 🪟 任意应用无极小窗 | 普通桌面 / 工作台 任意应用开启无极小窗 |
| ↕️ 强制上下分屏     | 实现竖屏上下分屏（仅 Android 15 支持） |
| 🚫 禁用分屏黑名单   | 所有应用都可加入分屏                   |
| 🔢 自定义小窗数量   | 普通桌面 / 工作台最多可设 8 个         |
| 🧊 隐藏小窗小白条   | 隐藏或沉浸小窗下方导航条               |
| 🎛️  窗口控制器 3.0  | 禁用任意应用的窗口顶栏三个点           |

> ⚙️ 所有功能的开关均可在 Web UI【完美横屏应用计划 → 系统体验增强】中进行设置，窗口控制器位于【完美横屏应用计划 → 窗口控制器】

---

## ⚠️ 使用须知：系统更新前请注意！

为避免系统更新后卡 MI，模块已内置如下保护机制：

- 当系统检测到 **更新后的 ROM** 时，模块会 **自动禁用**；
- 自动禁用机制 **仅适用于小米官方 ROM**，对于 **第三方移植包** 不保证生效；
- **强烈建议你在更新系统前**，手动卸载本模块以避免卡开机；

> 🔄 **每次系统更新后都需要重新前往 GitHub Actions 构建新的模块！**  
> 🛑 **请务必提前安装至少一个 Magisk 救砖模块或其他模块恢复工具，以防模块异常导致无法进入系统！**

---

## 📱 当前支持系统版本

✅ **已适配 Android 14 和 Android 15**，适用于小米平板各主流版本。

---

## 🚀 快速开始：构建你的专属模块

### 1️⃣ Fork 本项目

点击右上角 **Fork**，将本项目复制到你的 GitHub 账号中。

![fork 仓库](https://github.com/user-attachments/assets/daf22cc1-8a39-412e-9847-00d6e7e2999d)

---

### 2️⃣ 打开 Actions 页面

进入你的仓库，点击上方的 **Actions** 标签页，选择左侧 `构建 Magisk 模块`。

![进入 Actions](https://github.com/user-attachments/assets/5cf97d1b-dbcf-4c5c-91ba-1cb79508a09c)

---

### 3️⃣ 填写构建参数，运行 workflow

点击右上角 **Run workflow**，填写以下参数启动构建：

| 参数名 | 示例                                         | 说明              |
| ------ | -------------------------------------------- | ----------------- |
| `rom`  | `OS2.0.202.0.VOZCNXM`                        | ROM 版本号        |
| `url`  | `https://bigota.d.miui.com/xxx/miui_xxx.zip` | 官方 ROM 下载链接 |

📥 ROM 下载推荐：[https://hyperos.fans/](https://hyperos.fans/)

![运行 workflow](https://github.com/user-attachments/assets/3549eee0-6355-4cda-b2c6-80939665ca0c)

---

### 4️⃣ 下载模块

构建完成后，在页面底部 **Artifacts** 区块中下载生成的模块 ZIP 文件。

![下载构建产物](https://github.com/user-attachments/assets/4ef789c0-2f44-49f3-ac1c-397cc37b2f05)

---

## 📁 模块使用说明

下载的 ZIP 文件为 Magisk 模块，使用方法如下：

- 打开 Magisk App → 模块 → 从本地安装
- 或通过 TWRP 等第三方 Recovery 刷入

⚙️ 安装后，打开 **完美横屏应用计划 Web UI**，进入【系统体验增强】，即可设置开启或关闭相关功能，窗口控制器位于【完美横屏应用计划 → 窗口控制器】

---

## ❓ 常见问题

**Q：ROM 下载链接从哪里获取？**  
A：请访问 [https://hyperos.fans/](https://hyperos.fans/) 搜索对应设备版本。

**Q：适用于哪些设备？**  
A：推荐用于小米平板系列，需已解锁 Bootloader 并安装 Magisk。

**Q：构建失败怎么办？**  
A：请检查 ROM 链接是否有效，或提交 Issue 获取帮助。

**Q：为什么不生效？**  
A：请检查 系统界面 是否关闭默认卸载行为或者给予 系统界面 ROOT权限，并且检查模块是否由于版本不对处于禁用状态，或提交 Issue 获取帮助。

**Q：每次系统更新后都要重新构建吗？**  
A：✅ 是的，每次系统更新都需要重新运行 GitHub Actions 构建新的模块，确保兼容当前 ROM。

**Q：模块导致无法进入系统怎么办？**  
A：请在安装本模块前务必准备 **救砖方案**（如：启用 zrecovery、KSU Safe Mode 或 TWRP 模块管理），避免意外导致无法恢复系统。

---

## 🔄 Fork 用户同步更新

如果你已经 Fork 了本项目，后续项目更新（如支持新功能、修复问题）不会自动同步到你的仓库。你可以按以下方式同步更新：

### ✅ 方法一：GitHub 网页操作（适合不熟悉 Git 的用户）

1. 打开你的 Fork 仓库页面；
2. 点击右上方 `Sync fork` 按钮；
3. 点击 `Update branch`，即可同步主项目的更新。

![Fork 仓库同步主仓库更新](https://github.com/user-attachments/assets/4f5c5b4c-5ff7-4f22-a237-166b4f2aac56)

### 🧑‍💻 方法二：命令行同步（适合开发者）

```bash
# 添加上游仓库（只需执行一次）
git remote add upstream https://github.com/sothx/xiaomi_pad_system_patch_additional_module.git

# 获取上游更新并合并
git fetch upstream
git merge upstream/main

# 推送到你的 GitHub 仓库
git push origin main

```

## 🔧 移植包适配说明（供移植包作者参考）

如果你是 **第三方 ROM / 移植包作者**，为了保证模块相关功能在你的 ROM 中移植完整且不被 SELinux 拒绝，请确保以下几点：

### 1️⃣ 正确配置 `/product/etc/dot_black_list.json` 权限

为了避免 SELinux 拒绝操作该文件，必须补充以下权限项：

- **在 `/config/product_fs_config` 中追加：**

```bash
product/etc/dot_black_list.json 0 0 0644
```

- **在 `/config/product_file_contexts` 中追加：**

```bash
/product/etc/dot_black_list\.json u:object_r:system_file:s0
```

> ✅ 否则窗口控制器将无法生效，严重时可能卡 MI。

### 2️⃣ 所有 system.prop 属性应写入 `/product/etc/build.prop` 

为确保属性生效，请将所有模块在 `system.prop` 定义的属性写入：

```bash
/product/etc/build.prop
```

> ❌ 否则所有功能将丢失【完美横屏应用计划 Web UI】的支持，仅支持纯shell修改。

## 🤝 贡献者

欢迎提交 PR 支持更多功能或适配新设备！

@zjw2017

---

## 🛠 技术说明

- 使用 GitHub Actions 实现自动构建
- 基于 payload_extract 提取官方 ROM
- Bash 自动生成模块结构
- 支持 ext4 和 erofs 文件系统格式
- Android 14 和 Android 15 均已适配