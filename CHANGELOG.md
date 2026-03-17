# Changelog

## 1.1.1 — 2026-03-17

### Fixed
- Settings window now opens reliably from menu bar (replaced broken `NSApp.sendAction` hack with native `@Environment(\.openSettings)`)
- Preferred (pinned) input source no longer overridden by Bluetooth device connections (auto-restore now survives rapid CoreAudio callbacks and retries up to 3 times)

### Changed
- `ThemeManager` extracted from misnamed `SettingsWindowManager.swift` into its own file
- `ThemeManager` no longer uses unnecessary `@StateObject` wrapper in `InputControlApp`
- Deployment target raised to macOS 14 (was 13 in Info.plist, already 14 in Package.swift)

## 1.1.0 — 2026-03-17

### Fixed
- Preferred input device now persists correctly across reboots (previously stored a transient numeric ID that changed on restart)
- CoreAudio listener callback no longer has a data race when reading the change handler
- Auto-restore no longer fires after being cancelled (Task cancellation was silently ignored)
- Multiple rapid CoreAudio notifications no longer bypass intentional device selection (added 100ms debounce and time-based flag clearing)
- Fallback launch agent now actually launches at login (`RunAtLoad` was incorrectly set to `false`)
- Preferred input is restored after macOS wake (2s delay for Bluetooth devices to re-enumerate)
- CoreAudio CFString properties read with correct memory handling pattern
- Error messages now show human-readable descriptions instead of opaque numeric codes

### Changed
- Settings window replaced with native SwiftUI `Settings` scene (Cmd+, now works)
- Removed ~95 lines of custom NSWindow/NSHostingController/AnyView management
- Deprecated `NSApp.activate(ignoringOtherApps:)` replaced with availability-gated modern API
- Removed redundant `.fontDesign(.monospaced)` applications

## 1.0.0 — Initial Release

- Menu bar app for keeping your preferred microphone active
- One-click switching between available input devices
- Auto-restore preferred input when other devices connect
- Theme selection (light, dark, system)
- Launch at login support
- Device name display in menu bar (optional)
