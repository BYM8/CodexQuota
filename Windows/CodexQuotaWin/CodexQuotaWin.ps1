Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "SilentlyContinue"
$script:CodexHome = Join-Path $env:USERPROFILE ".codex"
$script:SessionsDir = Join-Path $script:CodexHome "sessions"
$script:Remaining = 0
$script:Used = 0
$script:Reset = "未知"
$script:Cycle = "未知"
$script:Plan = "未知"
$script:Updated = "未读取"

function Format-Cycle {
    param([double]$Minutes)
    if (-not $Minutes) { return "未知" }
    if ($Minutes -ge 1440) {
        return "$([math]::Round($Minutes / 1440)) 天"
    }
    return "$([math]::Max(1, [math]::Round($Minutes / 60))) 小时"
}

function Format-Time {
    param($UnixSeconds)
    if (-not $UnixSeconds) { return "未知" }
    try {
        return ([DateTimeOffset]::FromUnixTimeSeconds([int64]$UnixSeconds).LocalDateTime).ToString("M月d日 HH:mm")
    } catch {
        return "未知"
    }
}

function Read-CodexQuota {
    if (-not (Test-Path $script:SessionsDir)) { return }
    $files = Get-ChildItem $script:SessionsDir -Recurse -Filter *.jsonl |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 50

    foreach ($file in $files) {
        $lines = Get-Content $file.FullName -Tail 400
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            $line = $lines[$i]
            if ($line -notmatch '"token_count"' -or $line -notmatch '"rate_limits"') { continue }
            try {
                $obj = $line | ConvertFrom-Json
                if ($obj.payload.type -ne "token_count") { continue }
                $primary = $obj.payload.rate_limits.primary
                if ($null -eq $primary.used_percent) { continue }
                $script:Used = [math]::Max(0, [math]::Min(100, [int][math]::Round([double]$primary.used_percent)))
                $script:Remaining = 100 - $script:Used
                $script:Reset = Format-Time $primary.resets_at
                $script:Cycle = Format-Cycle $primary.window_minutes
                $script:Plan = if ($obj.payload.rate_limits.plan_type) { "$($obj.payload.rate_limits.plan_type)".ToUpper() } else { "未知" }
                $script:Updated = (Get-Date).ToString("M月d日 HH:mm")
                return
            } catch {
                continue
            }
        }
    }
}

function New-QuotaIcon {
    param([int]$Percent)
    $bitmap = New-Object System.Drawing.Bitmap 64, 64
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle 5, 5, 54, 54
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(88, 96, 235)), ([System.Drawing.Color]::FromArgb(34, 222, 165)), 90
    $g.FillEllipse($brush, $rect)
    $font = New-Object System.Drawing.Font "Segoe UI", 13, ([System.Drawing.FontStyle]::Bold)
    $text = "$Percent%"
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($text, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, 0, 64, 64), $format)
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $g.Dispose()
    return $icon
}

function Update-Tray {
    Read-CodexQuota
    $notifyIcon.Text = "Codex 余量 $script:Remaining% | 已用 $script:Used% | 重置 $script:Reset"
    $notifyIcon.Icon = New-QuotaIcon $script:Remaining
    $statusItem.Text = "剩余：$script:Remaining%`n已用：$script:Used%`n周期：$script:Cycle`n重置：$script:Reset`n套餐：$script:Plan`n更新：$script:Updated"
}

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true
$notifyIcon.Text = "Codex 余量"

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$statusItem = New-Object System.Windows.Forms.ToolStripMenuItem
$statusItem.Enabled = $false
$refreshItem = New-Object System.Windows.Forms.ToolStripMenuItem "立即刷新"
$openLogItem = New-Object System.Windows.Forms.ToolStripMenuItem "打开 Codex 日志目录"
$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem "退出"

$refreshItem.Add_Click({ Update-Tray })
$openLogItem.Add_Click({
    if (Test-Path $script:SessionsDir) {
        Start-Process explorer.exe $script:SessionsDir
    }
})
$exitItem.Add_Click({
    $timer.Stop()
    $notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})

[void]$menu.Items.Add($statusItem)
[void]$menu.Items.Add("-")
[void]$menu.Items.Add($refreshItem)
[void]$menu.Items.Add($openLogItem)
[void]$menu.Items.Add($exitItem)
$notifyIcon.ContextMenuStrip = $menu
$notifyIcon.Add_DoubleClick({ Update-Tray; $notifyIcon.ShowBalloonTip(3000, "Codex 余量", "剩余 $script:Remaining%，已用 $script:Used%，重置 $script:Reset", [System.Windows.Forms.ToolTipIcon]::Info) })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 30000
$timer.Add_Tick({ Update-Tray })
$timer.Start()
Update-Tray

[System.Windows.Forms.Application]::Run()
