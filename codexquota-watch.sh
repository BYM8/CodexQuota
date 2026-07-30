#!/usr/bin/env bash
set -euo pipefail

APP="/Applications/CodexQuota.app"

codex_running() {
  pgrep -f "/Applications/ChatGPT.app" >/dev/null 2>&1 || \
  pgrep -x "ChatGPT" >/dev/null 2>&1
}

quota_running() {
  pgrep -f "/Applications/CodexQuota.app/Contents/MacOS/CodexQuota" >/dev/null 2>&1
}

if [ -d "$APP" ] && codex_running && ! quota_running; then
  /usr/bin/open "$APP" >/dev/null 2>&1 || true
fi
