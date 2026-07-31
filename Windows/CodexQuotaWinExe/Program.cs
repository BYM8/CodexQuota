using System.Drawing.Drawing2D;
using System.Text.Json;
using System.Windows.Forms;

namespace CodexQuotaWin;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new TrayAppContext());
    }
}

internal sealed class TrayAppContext : ApplicationContext
{
    private readonly NotifyIcon notifyIcon;
    private readonly ToolStripMenuItem statusItem;
    private readonly System.Windows.Forms.Timer timer;
    private readonly QuotaReader reader = new();
    private QuotaSnapshot snapshot = QuotaSnapshot.Empty;

    public TrayAppContext()
    {
        statusItem = new ToolStripMenuItem("正在读取 Codex 余量...")
        {
            Enabled = false
        };

        var refreshItem = new ToolStripMenuItem("立即刷新", null, (_, _) => UpdateTray(showTip: true));
        var openLogItem = new ToolStripMenuItem("打开 Codex 日志目录", null, (_, _) => OpenLogFolder());
        var exitItem = new ToolStripMenuItem("退出", null, (_, _) => Exit());

        var menu = new ContextMenuStrip();
        menu.Items.Add(statusItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add(refreshItem);
        menu.Items.Add(openLogItem);
        menu.Items.Add(exitItem);

        notifyIcon = new NotifyIcon
        {
            Text = "Codex 余量",
            Visible = true,
            ContextMenuStrip = menu
        };
        notifyIcon.DoubleClick += (_, _) => UpdateTray(showTip: true);

        timer = new System.Windows.Forms.Timer
        {
            Interval = 30_000
        };
        timer.Tick += (_, _) => UpdateTray(showTip: false);
        timer.Start();

        UpdateTray(showTip: false);
    }

    private void UpdateTray(bool showTip)
    {
        snapshot = reader.ReadLatest() ?? snapshot;
        notifyIcon.Icon?.Dispose();
        notifyIcon.Icon = IconFactory.Create(snapshot.Remaining);
        notifyIcon.Text = TrimTooltip($"Codex 余量 {snapshot.Remaining}% | 已用 {snapshot.Used}% | 重置 {snapshot.Reset}");
        statusItem.Text =
            $"剩余：{snapshot.Remaining}%\n" +
            $"已用：{snapshot.Used}%\n" +
            $"周期：{snapshot.Cycle}\n" +
            $"重置：{snapshot.Reset}\n" +
            $"套餐：{snapshot.Plan}\n" +
            $"更新：{snapshot.Updated}";

        if (showTip)
        {
            notifyIcon.ShowBalloonTip(
                3000,
                "Codex 余量",
                $"剩余 {snapshot.Remaining}%，已用 {snapshot.Used}%，重置 {snapshot.Reset}",
                ToolTipIcon.Info
            );
        }
    }

    private void OpenLogFolder()
    {
        var sessions = QuotaReader.SessionsDirectory;
        if (Directory.Exists(sessions))
        {
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = sessions,
                UseShellExecute = true
            });
        }
    }

    private void Exit()
    {
        timer.Stop();
        notifyIcon.Visible = false;
        notifyIcon.Icon?.Dispose();
        notifyIcon.Dispose();
        Application.Exit();
    }

    private static string TrimTooltip(string text)
    {
        return text.Length <= 63 ? text : text[..63];
    }
}

internal sealed record QuotaSnapshot(
    int Remaining,
    int Used,
    string Reset,
    string Cycle,
    string Plan,
    string Updated
)
{
    public static QuotaSnapshot Empty { get; } = new(0, 0, "未知", "未知", "未知", "未读取");
}

internal sealed class QuotaReader
{
    public static string SessionsDirectory { get; } = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
        ".codex",
        "sessions"
    );

    public QuotaSnapshot? ReadLatest()
    {
        if (!Directory.Exists(SessionsDirectory))
        {
            return null;
        }

        IEnumerable<string> files;
        try
        {
            files = Directory.EnumerateFiles(SessionsDirectory, "*.jsonl", SearchOption.AllDirectories)
                .OrderByDescending(File.GetLastWriteTimeUtc)
                .Take(50)
                .ToArray();
        }
        catch
        {
            return null;
        }

        foreach (var file in files)
        {
            var snapshot = ParseFile(file);
            if (snapshot is not null)
            {
                return snapshot;
            }
        }

        return null;
    }

    private static QuotaSnapshot? ParseFile(string file)
    {
        string[] lines;
        try
        {
            lines = File.ReadLines(file).TakeLast(400).ToArray();
        }
        catch
        {
            return null;
        }

        for (var index = lines.Length - 1; index >= 0; index--)
        {
            var line = lines[index];
            if (!line.Contains("\"token_count\"") || !line.Contains("\"rate_limits\""))
            {
                continue;
            }

            try
            {
                using var doc = JsonDocument.Parse(line);
                var root = doc.RootElement;
                if (!root.TryGetProperty("payload", out var payload))
                {
                    continue;
                }

                if (!payload.TryGetProperty("type", out var type) || type.GetString() != "token_count")
                {
                    continue;
                }

                if (!payload.TryGetProperty("rate_limits", out var limits) ||
                    !limits.TryGetProperty("primary", out var primary) ||
                    !primary.TryGetProperty("used_percent", out var usedElement))
                {
                    continue;
                }

                var used = Math.Clamp((int)Math.Round(usedElement.GetDouble()), 0, 100);
                var remaining = 100 - used;
                var reset = primary.TryGetProperty("resets_at", out var resetElement)
                    ? FormatUnixTime(resetElement)
                    : "未知";
                var cycle = primary.TryGetProperty("window_minutes", out var windowElement)
                    ? FormatCycle(windowElement.GetDouble())
                    : "未知";
                var plan = limits.TryGetProperty("plan_type", out var planElement)
                    ? (planElement.GetString() ?? "未知").ToUpperInvariant()
                    : "未知";
                var updated = root.TryGetProperty("timestamp", out var timestampElement)
                    ? FormatTimestamp(timestampElement.GetString())
                    : DateTime.Now.ToString("M月d日 HH:mm");

                return new QuotaSnapshot(remaining, used, reset, cycle, plan, updated);
            }
            catch
            {
                continue;
            }
        }

        return null;
    }

    private static string FormatCycle(double minutes)
    {
        if (minutes >= 1440)
        {
            return $"{Math.Round(minutes / 1440)} 天";
        }

        return $"{Math.Max(1, Math.Round(minutes / 60))} 小时";
    }

    private static string FormatUnixTime(JsonElement element)
    {
        try
        {
            var seconds = element.ValueKind == JsonValueKind.Number ? element.GetInt64() : 0;
            return DateTimeOffset.FromUnixTimeSeconds(seconds).LocalDateTime.ToString("M月d日 HH:mm");
        }
        catch
        {
            return "未知";
        }
    }

    private static string FormatTimestamp(string? value)
    {
        if (value is not null && DateTimeOffset.TryParse(value, out var parsed))
        {
            return parsed.LocalDateTime.ToString("M月d日 HH:mm");
        }

        return DateTime.Now.ToString("M月d日 HH:mm");
    }
}

internal static class IconFactory
{
    public static Icon Create(int percent)
    {
        using var bitmap = new Bitmap(64, 64);
        using var g = Graphics.FromImage(bitmap);
        g.SmoothingMode = SmoothingMode.AntiAlias;

        using var background = new LinearGradientBrush(
            new Rectangle(5, 5, 54, 54),
            Color.FromArgb(88, 96, 235),
            Color.FromArgb(34, 222, 165),
            90f
        );
        g.FillEllipse(background, new Rectangle(5, 5, 54, 54));

        using var font = new Font("Segoe UI", 13f, FontStyle.Bold, GraphicsUnit.Point);
        using var format = new StringFormat
        {
            Alignment = StringAlignment.Center,
            LineAlignment = StringAlignment.Center
        };

        g.DrawString($"{percent}%", font, Brushes.White, new RectangleF(0, 0, 64, 64), format);

        var handle = bitmap.GetHicon();
        return (Icon)Icon.FromHandle(handle).Clone();
    }
}
