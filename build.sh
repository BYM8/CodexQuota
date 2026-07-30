#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/../../outputs"
APP="$OUT/CodexQuota.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
CACHE="$ROOT/.build-cache"

rm -rf "$APP"
mkdir -p "$MACOS" "$CONTENTS/Resources" "$CACHE"

swiftc \
  -O \
  -module-cache-path "$CACHE" \
  -framework Cocoa \
  "$ROOT/Sources/main.swift" \
  -o "$MACOS/CodexQuota"

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
if [ -f "$ROOT/Resources/CodexQuotaIcon.png" ]; then
  cp "$ROOT/Resources/CodexQuotaIcon.png" "$CONTENTS/Resources/CodexQuotaIcon.png"
fi
chmod +x "$MACOS/CodexQuota"

echo "$APP"
