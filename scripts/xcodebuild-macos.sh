#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild \
  -project "$ROOT_DIR/InputControl.xcodeproj" \
  -scheme InputControl \
  -destination 'generic/platform=macOS' \
  -configuration Release \
  build
