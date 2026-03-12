import CoreAudio
import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let preferredInputID = "preferredInputID"
        static let autoRestorePreferredInput = "autoRestorePreferredInput"
        static let launchAtLogin = "launchAtLogin"
        static let showsDeviceNameInMenuBar = "showsDeviceNameInMenuBar"
    }

    @Published var preferredInputID: AudioDeviceID? {
        didSet {
            if let preferredInputID {
                defaults.set(Int(preferredInputID), forKey: Key.preferredInputID)
            } else {
                defaults.removeObject(forKey: Key.preferredInputID)
            }
        }
    }

    @Published var autoRestorePreferredInput: Bool {
        didSet {
            defaults.set(autoRestorePreferredInput, forKey: Key.autoRestorePreferredInput)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
        }
    }

    @Published var showsDeviceNameInMenuBar: Bool {
        didSet {
            defaults.set(showsDeviceNameInMenuBar, forKey: Key.showsDeviceNameInMenuBar)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.preferredInputID) != nil {
            let storedValue = defaults.integer(forKey: Key.preferredInputID)
            self.preferredInputID = AudioDeviceID(storedValue)
        } else {
            self.preferredInputID = nil
        }

        if defaults.object(forKey: Key.autoRestorePreferredInput) != nil {
            self.autoRestorePreferredInput = defaults.bool(forKey: Key.autoRestorePreferredInput)
        } else {
            self.autoRestorePreferredInput = true
        }

        if defaults.object(forKey: Key.launchAtLogin) != nil {
            self.launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        } else {
            self.launchAtLogin = false
        }

        if defaults.object(forKey: Key.showsDeviceNameInMenuBar) != nil {
            self.showsDeviceNameInMenuBar = defaults.bool(forKey: Key.showsDeviceNameInMenuBar)
        } else {
            self.showsDeviceNameInMenuBar = true
        }
    }
}
