import AppKit
import CoreAudio

@MainActor
final class AudioDeviceStore: ObservableObject {
    @Published private(set) var devices: [AudioDevice] = []
    @Published private(set) var currentInputID: String?
    @Published private(set) var errorMessage: String?

    private let preferences: AppPreferences
    private let controller: CoreAudioController
    private var lastIntentionalSelectionUID: String?
    private var intentionalSelectionTimestamp: ContinuousClock.Instant?
    private var autoRestoreTask: Task<Void, Never>?
    private var autoRestoreTargetUID: String?
    private var autoRestoreRetryCount = 0
    private var debounceTask: Task<Void, Never>?
    private var wakeTask: Task<Void, Never>?
    private nonisolated(unsafe) var wakeObserver: NSObjectProtocol?

    init(preferences: AppPreferences) {
        self.preferences = preferences
        self.controller = CoreAudioController()
        self.controller.onChange = { [weak self] in
            Task { @MainActor in
                self?.scheduleHardwareChangeHandling()
            }
        }
        refresh()
        observeWakeNotifications()
    }

    deinit {
        autoRestoreTask?.cancel()
        debounceTask?.cancel()
        wakeTask?.cancel()
        if let wakeObserver {
            NotificationCenter.default.removeObserver(wakeObserver)
        }
    }

    private func observeWakeNotifications() {
        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWake()
            }
        }
    }

    private func handleWake() {
        wakeTask?.cancel()
        wakeTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            self?.handleAudioHardwareChange()
        }
    }

    var currentDevice: AudioDevice? {
        devices.first { $0.id == currentInputID }
    }

    func refresh() {
        do {
            let refreshedDevices = try controller.inputDevices()
            devices = refreshedDevices
            currentInputID = refreshedDevices.first(where: \.isDefault)?.id
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectInput(_ device: AudioDevice) {
        lastIntentionalSelectionUID = device.id
        intentionalSelectionTimestamp = .now

        do {
            try controller.setDefaultInputDevice(device.audioDeviceID)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeCurrentDevicePreferred() {
        preferences.preferredInputUID = currentInputID
    }

    /// Debounce rapid-fire CoreAudio notifications into a single handler call.
    /// CoreAudio commonly fires multiple callbacks for a single device change
    /// (one for device list, one for default input). Coalescing prevents the
    /// first callback from clearing intentional-selection state before the
    /// second arrives.
    private func scheduleHardwareChangeHandling() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                return
            }
            self?.handleAudioHardwareChange()
        }
    }

    private func handleAudioHardwareChange() {
        refresh()

        // Clear intentional-selection flag only if it was set recently (within 2s).
        // This prevents stale flags from suppressing auto-restore indefinitely.
        if let lastUID = lastIntentionalSelectionUID,
           currentInputID == lastUID {
            if let ts = intentionalSelectionTimestamp,
               ContinuousClock.now - ts < .seconds(2) {
                // Recent intentional selection confirmed — skip auto-restore this cycle
                lastIntentionalSelectionUID = nil
                intentionalSelectionTimestamp = nil
                return
            }
            // Stale flag — clear it and proceed with auto-restore logic
            lastIntentionalSelectionUID = nil
            intentionalSelectionTimestamp = nil
        }

        guard preferences.autoRestorePreferredInput else {
            return
        }

        guard let preferredUID = preferences.preferredInputUID else {
            return
        }

        guard currentInputID != preferredUID else {
            return
        }

        guard devices.contains(where: { $0.id == preferredUID }) else {
            return
        }

        // Don't cancel if the existing task is already restoring to the same device
        if autoRestoreTargetUID != preferredUID {
            autoRestoreTask?.cancel()
            autoRestoreRetryCount = 0
        } else if autoRestoreTask != nil {
            // Already working on restoring to this device — let it finish
            return
        }

        autoRestoreTargetUID = preferredUID
        autoRestoreTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return // Cancelled — don't restore
            }
            guard let self else {
                return
            }

            // Re-lookup by UID — AudioDeviceID may have changed after sleep
            guard let freshDevice = self.devices.first(where: { $0.id == preferredUID }) else {
                self.autoRestoreTargetUID = nil
                self.autoRestoreRetryCount = 0
                return
            }

            do {
                self.lastIntentionalSelectionUID = preferredUID
                self.intentionalSelectionTimestamp = .now
                try self.controller.setDefaultInputDevice(freshDevice.audioDeviceID)
                self.refresh()
            } catch {
                self.errorMessage = error.localizedDescription
                self.autoRestoreTargetUID = nil
                self.autoRestoreRetryCount = 0
                return
            }

            // Verification: re-check after a delay that the restore stuck
            self.scheduleAutoRestoreVerification(preferredUID: preferredUID)
        }
    }

    /// Verify the auto-restore actually stuck. macOS may switch back to a
    /// Bluetooth device after codec negotiation completes. Retry up to 3 times.
    private func scheduleAutoRestoreVerification(preferredUID: String) {
        autoRestoreTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return
            }
            guard let self else {
                return
            }

            self.refresh()

            if self.currentInputID == preferredUID {
                self.autoRestoreTargetUID = nil
                self.autoRestoreRetryCount = 0
                return
            }

            self.autoRestoreRetryCount += 1
            if self.autoRestoreRetryCount >= 3 {
                self.autoRestoreTargetUID = nil
                self.autoRestoreRetryCount = 0
                return
            }

            // Re-lookup by UID — AudioDeviceID may have changed after reconnection
            guard let freshDevice = self.devices.first(where: { $0.id == preferredUID }) else {
                self.autoRestoreTargetUID = nil
                self.autoRestoreRetryCount = 0
                return
            }

            do {
                self.lastIntentionalSelectionUID = preferredUID
                self.intentionalSelectionTimestamp = .now
                try self.controller.setDefaultInputDevice(freshDevice.audioDeviceID)
                self.refresh()
            } catch {
                self.errorMessage = error.localizedDescription
                self.autoRestoreTargetUID = nil
                self.autoRestoreRetryCount = 0
                return
            }

            self.scheduleAutoRestoreVerification(preferredUID: preferredUID)
        }
    }
}
