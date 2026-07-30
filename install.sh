#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_SOURCE="$ROOT/../../outputs/CodexQuota.app"
APP_TARGET="/Applications/CodexQuota.app"
AGENT_SOURCE="$ROOT/com.local.codexquota.plist"
AGENT_TARGET="$HOME/Library/LaunchAgents/com.local.codexquota.plist"
WATCH_SOURCE="$ROOT/com.local.codexquota.watch.plist"
WATCH_TARGET="$HOME/Library/LaunchAgents/com.local.codexquota.watch.plist"
WATCH_SCRIPT_SOURCE="$ROOT/codexquota-watch.sh"
WATCH_SCRIPT_TARGET="$HOME/Library/Application Support/CodexQuota/codexquota-watch.sh"
UID_VALUE="$(id -u)"

if [ ! -d "$APP_SOURCE" ]; then
  "$ROOT/build.sh"
fi

ditto "$APP_SOURCE" "$APP_TARGET"
codesign --force --deep --sign - "$APP_TARGET" >/dev/null

mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$HOME/Library/Application Support/CodexQuota"
cp "$AGENT_SOURCE" "$AGENT_TARGET"
cp "$WATCH_SOURCE" "$WATCH_TARGET"
cp "$WATCH_SCRIPT_SOURCE" "$WATCH_SCRIPT_TARGET"
chmod +x "$WATCH_SCRIPT_TARGET"

launchctl bootout "gui/$UID_VALUE" "$AGENT_TARGET" 2>/dev/null || true
launchctl bootstrap "gui/$UID_VALUE" "$AGENT_TARGET" || {
  echo "登录启动配置已写入，但当前会话未允许自动加载。请重新登录，或手动运行："
  echo "launchctl bootstrap gui/$UID_VALUE $AGENT_TARGET"
}
launchctl enable "gui/$UID_VALUE/com.local.codexquota" 2>/dev/null || true
launchctl bootout "gui/$UID_VALUE" "$WATCH_TARGET" 2>/dev/null || true
launchctl bootstrap "gui/$UID_VALUE" "$WATCH_TARGET" 2>/dev/null || true
launchctl enable "gui/$UID_VALUE/com.local.codexquota.watch" 2>/dev/null || true

open "$APP_TARGET" || true
echo "Installed: $APP_TARGET"
