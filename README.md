<p align="center">
  <img src="./assets/readme/hero.png" alt="Input Control hero" width="100%" />
</p>

<p align="center">
  <strong>Native macOS menu bar control for audio input switching.</strong><br />
  Built for the exact case where AirPods Max or other Bluetooth devices hijack your preferred microphone.
</p>

<p align="center">
  <a href="#download">Download</a>
  ·
  <a href="#what-it-does">Features</a>
  ·
  <a href="#build-from-source">Build</a>
  ·
  <a href="#release-artifacts">Release Artifacts</a>
</p>

## What It Does

Input Control lives in the macOS menu bar and gives you a fast, native way to:

- see the current audio input instantly
- switch between available input devices in one click
- set a preferred microphone
- automatically restore that preferred microphone if another device takes over
- choose a light, dark, or system-following theme
- configure launch at login from an in-app settings window

<p align="center">
  <img src="./assets/readme/settings-window.png" alt="Input Control settings preview" width="92%" />
</p>

## Why It Exists

Some Bluetooth devices, especially headphones with microphones, aggressively become the default input when they connect. This app keeps that behavior from derailing your actual setup.

If you want your USB mic, interface, or built-in mic to stay active, Input Control makes that state easy to see and easy to recover.

## Download

Download the current public build from the latest GitHub Release:

- [Latest release](https://github.com/emmagine79/input-control/releases/latest)
- Asset: `Input-Control-macOS-universal.zip`

## If macOS Blocks the App

Current public builds are release-ready, but they are not notarized yet. If macOS flags the app on first launch:

1. Move `Input Control.app` into `/Applications`.
2. Try to open it once, then dismiss the warning.
3. Open `Apple menu -> System Settings -> Privacy & Security`.
4. Scroll to the `Security` section and click `Open Anyway`.
5. Confirm the second prompt and authenticate with your Mac password or Touch ID.

Apple notes that `Open Anyway` is only available for about one hour after the blocked launch attempt.

Reference:

- [Open a Mac app from an unknown developer](https://support.apple.com/guide/mac-help/mh40616/mac)
- [Safely open apps on your Mac](https://support.apple.com/102445)

## Build From Source

### Build the app

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh --run
```

Output:

- `dist/Input Control.app`

### Install to `/Applications`

```bash
chmod +x scripts/install-app.sh
./scripts/install-app.sh
```

## Release Artifacts

To generate the exact files intended for GitHub Releases:

```bash
chmod +x scripts/build-release.sh
./scripts/build-release.sh
```

Output:

- `release/Input-Control-macOS-universal.zip`
- `release/SHA256SUMS.txt`

## Recommended Setup

1. Install the app to `/Applications`.
2. Open it once manually.
3. In Settings, pick your preferred input and theme.
4. Enable `Launch at login` if you want the app active on every boot.

## Project Layout

- `InputControl.xcodeproj` is the primary app target for shipping and signing.
- `Sources/` contains the native SwiftUI and AppKit implementation.
- `Resources/Assets.xcassets` contains the app icon asset catalog.
- `scripts/build-release.sh` creates release-ready archives for GitHub Releases.
