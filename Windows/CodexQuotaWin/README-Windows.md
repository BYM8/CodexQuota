# CodexQuotaWin

Windows PowerShell 托盘版 Codex 余量工具。

## 安装

新版 Windows 包不再提供自动安装脚本，避免被安全软件误判。

解压后双击或右键运行：

```text
Start-CodexQuotaWin.bat
```

这个启动脚本只做一件事：用 PowerShell 打开本目录里的 `CodexQuotaWin.ps1`。

它不会：

- 下载任何文件
- 隐藏运行
- 绕过执行策略
- 自动写入开机启动项

## 使用

- 右键托盘图标查看状态
- 双击托盘图标弹出当前余量
- 右键选择「立即刷新」手动读取最新日志
- 右键选择「打开 Codex 日志目录」查看本机日志

## 卸载

右键托盘图标选择「退出」，然后删除解压出来的文件夹即可。

如果你之前安装过旧版，请先删除：

```text
%LOCALAPPDATA%\CodexQuotaWin
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CodexQuotaWin.lnk
```
