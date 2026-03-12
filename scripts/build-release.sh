#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/Input Control.app"
RELEASE_DIR="$ROOT_DIR/release"
ZIP_PATH="$RELEASE_DIR/Input-Control-macOS-universal.zip"
CHECKSUM_PATH="$RELEASE_DIR/SHA256SUMS.txt"

"$ROOT_DIR/scripts/build-app.sh"

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$CHECKSUM_PATH")"
)

printf 'Created %s\n' "$ZIP_PATH"
printf 'Created %s\n' "$CHECKSUM_PATH"
