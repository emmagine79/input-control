#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET_DIR="$ROOT_DIR/.build/InputControl.iconset"
ICNS_PATH="$ROOT_DIR/Resources/InputControl.icns"
ASSET_ICONSET_DIR="$ROOT_DIR/Resources/Assets.xcassets/AppIcon.appiconset"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
mkdir -p "$ASSET_ICONSET_DIR"

typeset -A sizes=(
  [icon_16x16]=16
  [icon_16x16@2x]=32
  [icon_32x32]=32
  [icon_32x32@2x]=64
  [icon_128x128]=128
  [icon_128x128@2x]=256
  [icon_256x256]=256
  [icon_256x256@2x]=512
  [icon_512x512]=512
  [icon_512x512@2x]=1024
)

for name size in ${(kv)sizes}; do
  swift "$ROOT_DIR/scripts/generate-icon.swift" "$ICONSET_DIR/$name.png" "$size"
  cp "$ICONSET_DIR/$name.png" "$ASSET_ICONSET_DIR/$name.png"
done

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
printf 'Generated %s\n' "$ICNS_PATH"
printf 'Updated %s\n' "$ASSET_ICONSET_DIR"
