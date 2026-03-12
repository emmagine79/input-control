#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="$ROOT_DIR/.build/XcodeDerivedData"
APP_DIR="$ROOT_DIR/dist/Input Control.app"
XCODE_APP_DIR="$DERIVED_DATA_DIR/Build/Products/Release/Input Control.app"

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

"$ROOT_DIR/scripts/generate-icon.sh"

xcodebuild \
  -project "$ROOT_DIR/InputControl.xcodeproj" \
  -scheme InputControl \
  -destination 'generic/platform=macOS' \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build

rm -rf "$APP_DIR"
cp -R "$XCODE_APP_DIR" "$APP_DIR"

if [[ "${1:-}" == "--run" ]]; then
  open "$APP_DIR"
fi

printf 'Built %s\n' "$APP_DIR"
