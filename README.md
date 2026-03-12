# Input Control

Native macOS menu bar utility for quickly switching audio input devices, now with a full Xcode app target.

## What it does

- Shows the current audio input directly in the menu bar
- Lets you switch inputs from a Tahoe-style menu bar panel
- Includes a native Settings window for startup and preferred-input behavior
- Can automatically switch back to your preferred input when another device takes over

## Build and run

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh --run
```

The built app bundle is placed at `dist/Input Control.app`.

## Install to Applications

```bash
chmod +x scripts/install-app.sh
./scripts/install-app.sh
```

This builds the app, installs it to `/Applications/Input Control.app`, and opens it.

## Open in Xcode

```bash
chmod +x scripts/open-in-xcode.sh scripts/xcodebuild-macos.sh
./scripts/open-in-xcode.sh
```

If you want to build the full app target from the command line with Xcode:

```bash
./scripts/xcodebuild-macos.sh
```

## Recommended setup

1. Install the app to `/Applications`.
2. Open the app once.
3. In Settings, choose your preferred input and enable `Launch at login` if you want it to start with macOS.

## Project layout

- `InputControl.xcodeproj` is the primary macOS app target for signing and shipping.
- `Package.swift` remains as a lightweight Swift package entry point for code reuse and fallback builds.
