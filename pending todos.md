# Input Control — Pending Todos

**Current version**: 1.0 (build 1)
**Internal dev version**: 1.0.1-dev

---

## Phase 1: Critical Data & Threading Bugs
_Files: CoreAudioController.swift, AppPreferences.swift, AudioDevice.swift, AudioDeviceStore.swift_

- [x] **C1** — Persist device UID string instead of AudioDeviceID *(done 2026-03-17, build 2)*
- [x] **C2** — Fix data race on `onChange` closure in CoreAudioController *(done 2026-03-17, build 2)*

## Phase 2: Auto-Restore Logic Bugs
_Files: AudioDeviceStore.swift, LaunchAtLoginManager.swift_

- [x] **H1** — Fix CancellationError swallowing in auto-restore *(done 2026-03-17, build 3)*
- [x] **H2** — Debounce hardware change + time-based intentional-selection clearing *(done 2026-03-17, build 3)*
- [x] **H3** — Fix `RunAtLoad: false` → `true` in launch agent plist *(done 2026-03-17, build 3)*

## Phase 3: Reliability Improvements
_Files: AudioDeviceStore.swift, CoreAudioController.swift, AppPreferences.swift_

- [ ] **M1** — Add sleep/wake listener for post-wake device restore
  - Listen for `NSWorkspace.didWakeNotification`, trigger delayed refresh
- [ ] **M2** — Fix `takeUnretainedValue()` in `deviceName()` — potential memory issue
- [ ] **M3** — Make `errorMessage` in AudioDeviceStore `private(set)`
- [ ] **M4** — Add human-readable OSStatus error messages for common CoreAudio errors

## Phase 4: SwiftUI Architecture (Settings Window)
_Files: SettingsWindowManager.swift, InputControlApp.swift, MenuBarContentView.swift_

- [ ] **S1** — Replace custom NSWindow settings with SwiftUI `Settings` scene
  - Eliminates SettingsWindowManager entirely
  - Gains Cmd+, shortcut for free
  - Removes AnyView type erasure
- [ ] **S2** — Remove redundant `.fontDesign(.monospaced)` applications
- [ ] **S3** — Fix deprecated `NSApp.activate(ignoringOtherApps:)` (macOS 14+)

---

## Post-Fix

- [ ] Final compile + test pass
- [ ] Bump version to 1.1.0
- [ ] Update CHANGELOG
- [ ] Push as release to GitHub
