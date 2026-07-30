#!/usr/bin/env bash
set -euo pipefail

AGENT_TARGET="$HOME/Library/LaunchAgents/com.local.codexquota.plist"
WATCH_TARGET="$HOME/Library/LaunchAgents/com.local.codexquota.watch.plist"
WATCH_SCRIPT_TARGET="$HOME/Library/Application Support/CodexQuota/codexquota-watch.sh"
UID_VALUE="$(id -u)"

launchctl bootout "gui/$UID_VALUE" "$AGENT_TARGET" 2>/dev/null || true
launchctl bootout "gui/$UID_VALUE" "$WATCH_TARGET" 2>/dev/null || true
osascript -e 'tell application "CodexQuota" to quit' 2>/dev/null || true

if [ -d "/Applications/CodexQuota.app" ]; then
  osascript -e 'tell application "Finder" to move POSIX file "/Applications/CodexQuota.app" to trash' 2>/dev/null || true
fi

if [ -f "$AGENT_TARGET" ]; then
  osascript -e 'tell application "Finder" to move POSIX file "'"$AGENT_TARGET"'" to trash' 2>/dev/null || true
fi

if [ -f "$WATCH_TARGET" ]; then
  osascript -e 'tell application "Finder" to move POSIX file "'"$WATCH_TARGET"'" to trash' 2>/dev/null || true
fi

if [ -f "$WATCH_SCRIPT_TARGET" ]; then
  osascript -e 'tell application "Finder" to move POSIX file "'"$WATCH_SCRIPT_TARGET"'" to trash' 2>/dev/null || true
fi

echo "Uninstalled CodexQuota"
