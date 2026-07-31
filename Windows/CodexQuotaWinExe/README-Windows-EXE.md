# CodexQuotaWin.exe

这是 Windows 原生托盘版 Codex 余量工具。

## 普通用户

请到 Releases 下载：

```text
CodexQuota-Windows-EXE.zip
```

解压后双击：

```text
CodexQuotaWin.exe
```

## 功能

- 自动读取 `%USERPROFILE%\.codex\sessions` 下的 Codex 会话日志
- 每 30 秒刷新一次
- 右下角系统托盘显示余量
- 右键托盘图标可刷新、打开日志目录、退出
- 不下载文件
- 不隐藏脚本
- 不绕过 PowerShell 执行策略
- 不自动写入开机启动

## 开发者构建

需要 Windows 或安装了 .NET SDK 的构建环境：

```powershell
dotnet publish .\Windows\CodexQuotaWinExe\CodexQuotaWinExe.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true
```

输出位置：

```text
Windows\CodexQuotaWinExe\bin\Release\net8.0-windows\win-x64\publish\CodexQuotaWin.exe
```
