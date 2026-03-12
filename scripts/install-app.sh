#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_SOURCE="$ROOT_DIR/dist/Input Control.app"
APP_DESTINATION="/Applications/Input Control.app"

"$ROOT_DIR/scripts/build-app.sh"
rm -rf "$APP_DESTINATION"
cp -R "$APP_SOURCE" "$APP_DESTINATION"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DESTINATION" >/dev/null 2>&1 || true
fi

open "$APP_DESTINATION"
printf 'Installed %s\n' "$APP_DESTINATION"
