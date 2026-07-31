# Codex 余量

一个原生 macOS 菜单栏小应用，用来显示 Codex 余量状态。

## 制作署名

程橙Ai 联合老表软件库 制作

联系方式：30810511@qq.com

## 开源协议

本项目采用 MIT License 开源，欢迎学习、二次开发和分享。

## 普通用户怎么安装

不要直接下载 GitHub 绿色的 `Code` 源码包。普通用户请进入 Releases 下载已经打包好的版本：

```text
https://github.com/BYM8/CodexQuota/releases
```

在 Releases 页面选择：

- macOS 用户下载 `CodexQuota-macOS.zip`
- Windows 用户优先下载 `CodexQuota-Windows-EXE.zip`
- Windows 备用脚本版下载 `CodexQuota-Windows.zip`
- 想看源码或二次开发，再下载 `Source code`

### macOS 安装

1. 下载 `CodexQuota-macOS.zip`
2. 解压后得到 `CodexQuota.app`
3. 双击打开，或者拖到「应用程序」文件夹
4. 启动后在顶部菜单栏查看余量百分比
5. 如果系统提示来自互联网，请在「系统设置 > 隐私与安全性」里允许打开

### Windows 安装

推荐使用 EXE 版：

1. 下载 `CodexQuota-Windows-EXE.zip`
2. 解压到一个固定文件夹，例如桌面或文档目录
3. 打开 `CodexQuotaWin` 文件夹
4. 双击运行 `CodexQuotaWin.exe`
5. 启动后在右下角系统托盘查看图标
6. 右键托盘图标可以「立即刷新」「打开 Codex 日志目录」「退出」

Windows EXE 版不会下载文件、不会隐藏脚本、不会绕过执行策略、不会自动写开机启动。如果安全软件提示，请确认文件名来自本项目 Release：`CodexQuota-Windows-EXE.zip`。

如果你的系统无法运行 EXE 版，可以下载备用脚本版 `CodexQuota-Windows.zip`，解压后运行 `Start-CodexQuotaWin.bat`。

## 环境

- macOS 12 或更高版本
- Apple Command Line Tools，包含 `swiftc`

## 构建

```bash
./build.sh
```

构建产物会生成到：

```text
../../outputs/CodexQuota.app
```

## 使用

打开 `CodexQuota.app` 后，菜单栏会显示当前剩余百分比。点击菜单栏百分比可以打开详情面板。

## 安装

```bash
./install.sh
```

安装内容：

- `/Applications/CodexQuota.app`
- `~/Library/LaunchAgents/com.local.codexquota.plist`
- `~/Library/LaunchAgents/com.local.codexquota.watch.plist`
- `~/Library/Application Support/CodexQuota/codexquota-watch.sh`

## 卸载

```bash
./uninstall.sh
```

## 下载安装包

已发布安装包请到 Releases 下载：

- `CodexQuota-macOS.zip`：macOS 菜单栏应用
- `CodexQuota-Windows-EXE.zip`：Windows EXE 托盘版，推荐普通用户使用
- `CodexQuota-Windows.zip`：Windows PowerShell 托盘版，备用

Releases 地址：

```text
https://github.com/BYM8/CodexQuota/releases
```

## Windows 版本

Windows EXE 版源码位于：

```text
Windows/CodexQuotaWinExe
```

Windows PowerShell 备用版位于：

```text
Windows/CodexQuotaWin
```

EXE 版解压后运行：

```text
CodexQuotaWin.exe
```

备用脚本版解压后运行：

```text
Start-CodexQuotaWin.bat
```

新版 Windows 包不会隐藏运行、不会绕过执行策略、不会自动写开机启动。退出时右键托盘图标选择：

```text
退出
```

## 中文说明书

详细中文说明见：

```text
docs/中文说明书.md
```
