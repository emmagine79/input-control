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
