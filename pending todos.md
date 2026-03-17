# Input Control — Pending Todos

**Current version**: 1.2.0 (build 8)
**Internal dev version**: 1.2.1-dev

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

- [x] Final compile + test pass *(all 4 phases compiled clean with both SPM and xcodebuild)*
- [x] Bump version to 1.1.0 (build 6) *(done 2026-03-17)*
- [x] Update CHANGELOG *(done 2026-03-17)*
- [x] Push as release to GitHub *(done 2026-03-17, v1.1.0)*

---

## v1.1.1 — Bug Fixes (found 2026-03-17 post-release audit)

### Phase 5: Settings Window Fix
_Files: MenuBarContentView.swift, AppNavigation.swift_

- [x] **B1** — Settings window does not open from menu bar *(done 2026-03-17, build 7)*
  - **Root cause:** `NSApp.sendAction(Selector(("showSettingsWindow:")))` is unreliable in MenuBarExtra-only apps — no responder in the chain handles it
  - **Fix:** Use `@Environment(\.openSettings)` (macOS 14+) directly in `MenuBarContentView` footer button instead of routing through `AppNavigation.openSettings()`. For macOS 13, fall back to `NSApp.sendAction` but call `NSApp.activate(ignoringOtherApps: true)` BEFORE the action, not after
  - **Validation:** Click "Settings…" button in menu bar dropdown → window must appear and come to front

### Phase 6: Auto-Restore Reliability
_Files: AudioDeviceStore.swift_

- [x] **B2** — Pinned (preferred) source overridden by newly connected Bluetooth device *(done 2026-03-17, build 7)*
  - **Root cause:** Bluetooth connections fire multiple CoreAudio callbacks over several seconds (device list, default input, codec negotiation). Each callback cancels the pending `autoRestoreTask` (line 145) before 350ms elapses. If the final callback's restore is also cancelled by a late callback, auto-restore silently gives up.
  - **Fix:** Replace single-shot auto-restore with a resilient approach:
    1. Don't cancel `autoRestoreTask` if it's already targeting the correct preferred device
    2. After the debounced handler completes, schedule a "verification check" at ~2s that re-checks whether the input matches preferred and retries if not
    3. Add a max-retry cap (e.g., 3 attempts) to avoid infinite loops with devices that macOS forcefully redirects
  - **Validation:** Connect a Bluetooth headset → input should snap back to the pinned source within a few seconds

### Phase 7: Cleanup
_Files: SettingsWindowManager.swift → ThemeManager.swift, InputControlApp.swift_

- [x] **B3** — Rename `SettingsWindowManager.swift` to `ThemeManager.swift` *(done 2026-03-17, build 7)* (it only contains `ThemeManager` after Phase 4 removed the old settings window code)
- [x] **B4** — `ThemeManager` is created in `InputControlApp` but never injected *(done 2026-03-17, build 7)* as `.environmentObject()` — works by accident via Combine subscription, but fragile. Either inject it or keep it as a plain stored property (not `@StateObject`) since no view reads from it

### Post-Fix

- [x] Compile + test pass *(done 2026-03-17, build 7)*
- [x] Bump version to 1.1.1 *(done 2026-03-17)*
- [x] Update CHANGELOG *(done 2026-03-17)*
- [x] Build timestamped artifact to dist/ *(done 2026-03-17)*
- [x] Push as release to GitHub *(done 2026-03-17, v1.1.1)*
