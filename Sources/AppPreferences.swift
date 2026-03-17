import AppKit
import Foundation

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "Follow System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var windowAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let preferredInputID = "preferredInputID"
        static let autoRestorePreferredInput = "autoRestorePreferredInput"
        static let launchAtLogin = "launchAtLogin"
        static let showsDeviceNameInMenuBar = "showsDeviceNameInMenuBar"
        static let theme = "theme"
    }

    @Published var preferredInputUID: String? {
        didSet {
            if let preferredInputUID {
                defaults.set(preferredInputUID, forKey: Key.preferredInputID)
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

    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Key.theme)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let storedUID = defaults.string(forKey: Key.preferredInputID) {
            self.preferredInputUID = storedUID
        } else if defaults.object(forKey: Key.preferredInputID) != nil {
            // Migration: clear legacy integer-based device ID
            defaults.removeObject(forKey: Key.preferredInputID)
            self.preferredInputUID = nil
        } else {
            self.preferredInputUID = nil
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

        if let storedTheme = defaults.string(forKey: Key.theme),
           let theme = AppTheme(rawValue: storedTheme) {
            self.theme = theme
        } else {
            self.theme = .system
        }
    }
}
