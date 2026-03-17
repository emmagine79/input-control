# Input Control — Development Log

This file tracks all changes made to the project, when they were made, and why.

---

## 2026-03-17 — Project Audit & Bug Fix Plan

**What**: Full SwiftUI + engineering review of the codebase.

**Findings**:
- 2 critical bugs (unstable device ID persistence, CoreAudio threading race)
- 3 high-priority bugs (broken cancellation in auto-restore, intentional-selection bypass, launch agent RunAtLoad=false)
- 4 medium improvements (sleep/wake handling, memory safety in deviceName, error visibility, OSStatus messages)
- 3 SwiftUI architecture items (Settings scene, redundant modifiers, deprecated API)

**Plan**: Fix in 4 phases grouped by similarity. Each phase gets compiled, tested, and pushed as a rollback point with internal version bump.

**Files created**:
- `pending todos.md` — phased fix plan
- `DEVLOG.md` — this file

---

## 2026-03-17 — Phase 1: Critical Data & Threading Bugs (build 2)

**C1: Persist device UID string instead of AudioDeviceID**
- Added `deviceUID(deviceID:)` and `deviceID(forUID:)` to CoreAudioController
- Changed `AudioDevice.id` from `AudioDeviceID` (UInt32) to `String` (stable UID)
- Added `AudioDevice.audioDeviceID` for runtime CoreAudio operations
- Renamed `AppPreferences.preferredInputID` → `preferredInputUID` (String?)
- Added migration path: old integer values are cleared on first launch
- Updated `AudioDeviceStore` to work with UID strings throughout
- Updated `SettingsView` and `MenuBarContentView` for new UID-based API
- Fixed sorting in `inputDevices()` to use `.isDefault` instead of comparing IDs

**C2: Fix data race on onChange closure**
- Made `CoreAudioController` conform to `@unchecked Sendable`
- Protected `onChange` with `NSLock` — CoreAudio callbacks read it safely from arbitrary threads
- Stored backing `_onChange` privately, exposed thread-safe computed `onChange`

**Files touched**: CoreAudioController.swift, AudioDevice.swift, AudioDeviceStore.swift, AppPreferences.swift, SettingsView.swift, MenuBarContentView.swift, Info.plist

---

## 2026-03-17 — Phase 2: Auto-Restore Logic Bugs (build 3)

**H1: Fix CancellationError swallowing**
- Changed `try?` to `try` in Task.sleep, catching cancellation to return early
- Previously, cancelled tasks would continue and restore the device anyway

**H2: Debounce hardware change + time-based intentional-selection**
- Added 100ms debounce on CoreAudio hardware change callbacks via `scheduleHardwareChangeHandling()`
- CoreAudio commonly fires multiple callbacks for a single change; debouncing coalesces them
- Changed `lastIntentionalSelectionUID` clearing to be time-based (2s window)
- Prevents stale flags from suppressing auto-restore indefinitely

**H3: Fix RunAtLoad in launch agent plist**
- Changed `"RunAtLoad": false` to `"RunAtLoad": true` in `writeLaunchAgent()`
- The fallback launch agent was being created but never actually launching at login

**Files touched**: AudioDeviceStore.swift, LaunchAtLoginManager.swift, Info.plist, pending todos.md

---

## 2026-03-17 — Phase 3: Reliability Improvements (build 4)

**M1: Sleep/wake listener**
- Added `NSWorkspace.didWakeNotification` observer in AudioDeviceStore
- On wake, waits 2 seconds then triggers hardware change handling
- Ensures preferred device is restored after Bluetooth devices reconnect post-sleep

**M2: Fixed CFString handling**
- Created shared `readCFString(from:address:context:)` helper
- Uses `Unmanaged<CFString>?` with `takeUnretainedValue()` (CF "Get" rule)
- Applied to both `deviceName` and `deviceUID` for consistency
- Eliminates previous warning about forming UnsafeMutableRawPointer to CFString

**M3: errorMessage visibility**
- Already fixed as `private(set)` in Phase 1 — no additional change needed

**M4: Human-readable OSStatus errors**
- Added lookup table in `AudioDeviceError` for common CoreAudio status codes
- Covers: hardware not running, bad device, bad stream, unsupported operation, unsupported format, unknown property, bad property size
- Users now see "the device does not exist or was disconnected" instead of opaque numbers

**Files touched**: CoreAudioController.swift, AudioDeviceStore.swift, Info.plist, pending todos.md

---

## 2026-03-17 — Phase 4: SwiftUI Architecture (build 5)

**S1: Replace custom settings window with Settings scene**
- Deleted `SettingsWindowManager` (95 lines of NSWindow/NSHostingController/AnyView management)
- Replaced with slim `ThemeManager` (~25 lines) that only applies NSApp.appearance
- Added `Settings { SettingsView() }` scene to InputControlApp
- MenuBarContentView no longer depends on SettingsWindowManager
- Settings button now calls `AppNavigation.openSettings()` which uses native `sendAction`
- Gains Cmd+, keyboard shortcut automatically

**S2: Removed redundant .fontDesign(.monospaced)**
- Removed from MenuBarExtra label (was redundant with inline font in MenuBarLabelView)
- Removed from MenuBarContentView body (kept at MenuBarExtra content level in InputControlApp)
- SettingsView keeps its own application (it's the root of the Settings scene)

**S3: Fixed deprecated NSApp.activate(ignoringOtherApps:)**
- Uses `NSApp.activate()` on macOS 14+
- Falls back to `NSApp.activate(ignoringOtherApps: true)` on macOS 13

**Files touched**: SettingsWindowManager.swift (rewritten as ThemeManager), InputControlApp.swift, MenuBarContentView.swift, AppNavigation.swift, Info.plist, pending todos.md
