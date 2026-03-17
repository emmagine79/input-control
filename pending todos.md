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

- [x] **M1** — Sleep/wake listener for post-wake restore *(done 2026-03-17, build 4)*
- [x] **M2** — Fixed CFString handling with shared `readCFString` helper *(done 2026-03-17, build 4)*
- [x] **M3** — `errorMessage` already `private(set)` *(done in Phase 1)*
- [x] **M4** — Human-readable OSStatus error messages *(done 2026-03-17, build 4)*

## Phase 4: SwiftUI Architecture (Settings Window)
_Files: SettingsWindowManager.swift, InputControlApp.swift, MenuBarContentView.swift_

- [x] **S1** — Replaced custom NSWindow with SwiftUI `Settings` scene *(done 2026-03-17, build 5)*
- [x] **S2** — Removed redundant `.fontDesign(.monospaced)` *(done 2026-03-17, build 5)*
- [x] **S3** — Fixed deprecated `NSApp.activate(ignoringOtherApps:)` with availability gate *(done 2026-03-17, build 5)*

---

## Post-Fix

- [ ] Final compile + test pass
- [ ] Bump version to 1.1.0
- [ ] Update CHANGELOG
- [ ] Push as release to GitHub
