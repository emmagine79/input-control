import CoreAudio
import Foundation

@MainActor
final class AudioDeviceStore: ObservableObject {
    @Published private(set) var devices: [AudioDevice] = []
    @Published private(set) var currentInputID: AudioDeviceID?
    @Published var errorMessage: String?

    private let preferences: AppPreferences
    private let controller: CoreAudioController
    private var lastIntentionalSelectionID: AudioDeviceID?
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
        lastIntentionalSelectionID = device.id

        do {
            try controller.setDefaultInputDevice(device.id)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeCurrentDevicePreferred() {
        preferences.preferredInputID = currentInputID
    }

    private func handleAudioHardwareChange() {
        refresh()

        guard currentInputID != lastIntentionalSelectionID else {
            lastIntentionalSelectionID = nil
            return
        }

        guard preferences.autoRestorePreferredInput else {
            return
        }

        guard let preferredInputID = preferences.preferredInputID else {
            return
        }

        guard currentInputID != preferredInputID else {
            return
        }

        guard devices.contains(where: { $0.id == preferredInputID }) else {
            return
        }

        autoRestoreTask?.cancel()
        autoRestoreTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard let self else {
                return
            }

            do {
                self.lastIntentionalSelectionID = preferredInputID
                try self.controller.setDefaultInputDevice(preferredInputID)
                self.refresh()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
