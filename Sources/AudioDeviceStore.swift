import AppKit
import CoreAudio
import Foundation

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
    private var debounceTask: Task<Void, Never>?
    private var wakeTask: Task<Void, Never>?

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
        NotificationCenter.default.removeObserver(self)
    }

    private func observeWakeNotifications() {
        NotificationCenter.default.addObserver(
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

        guard let preferredDevice = devices.first(where: { $0.id == preferredUID }) else {
            return
        }

        autoRestoreTask?.cancel()
        autoRestoreTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return // Cancelled — don't restore
            }
            guard let self else {
                return
            }

            do {
                self.lastIntentionalSelectionUID = preferredUID
                self.intentionalSelectionTimestamp = .now
                try self.controller.setDefaultInputDevice(preferredDevice.audioDeviceID)
                self.refresh()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
