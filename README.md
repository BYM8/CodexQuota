# Codex 余量

一个原生 macOS 菜单栏小应用，用来显示 Codex 余量状态。

## 制作署名

程橙Ai 联合老表软件库 制作

联系方式：30810511@qq.com

## 开源协议

本项目采用 MIT License 开源，欢迎学习、二次开发和分享。

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

## Windows 版本

Windows PowerShell 托盘版位于：

```text
Windows/CodexQuotaWin
```

解压 Windows 安装包后，右键运行：

```text
install.bat
```

卸载时运行：

```text
uninstall.bat
```

## 中文说明书

详细中文说明见：

```text
docs/中文说明书.md
```
