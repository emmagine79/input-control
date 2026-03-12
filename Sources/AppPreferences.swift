import AppKit
import CoreAudio
import Foundation
import SwiftUI

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

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func resolvedColorScheme(for appearance: NSAppearance) -> ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua ? .dark : .light
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

    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Key.theme)
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

        if let storedTheme = defaults.string(forKey: Key.theme),
           let theme = AppTheme(rawValue: storedTheme) {
            self.theme = theme
        } else {
            self.theme = .system
        }
    }
}
