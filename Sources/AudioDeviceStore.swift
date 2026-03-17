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
    private var autoRestoreTask: Task<Void, Never>?

    init(preferences: AppPreferences) {
        self.preferences = preferences
        self.controller = CoreAudioController()
        self.controller.onChange = { [weak self] in
            Task { @MainActor in
                self?.handleAudioHardwareChange()
            }
        }
        refresh()
    }

    deinit {
        autoRestoreTask?.cancel()
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

    private func handleAudioHardwareChange() {
        refresh()

        guard currentInputID != lastIntentionalSelectionUID else {
            lastIntentionalSelectionUID = nil
            return
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
            try? await Task.sleep(for: .milliseconds(350))
            guard let self else {
                return
            }

            do {
                self.lastIntentionalSelectionUID = preferredUID
                try self.controller.setDefaultInputDevice(preferredDevice.audioDeviceID)
                self.refresh()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
