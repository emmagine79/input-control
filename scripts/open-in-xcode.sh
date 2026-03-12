#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
open -a /Applications/Xcode.app "$ROOT_DIR/InputControl.xcodeproj"
