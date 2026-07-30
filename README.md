# Codex 余量

一个原生 macOS 菜单栏小应用，用来显示 Codex 余量状态。

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
