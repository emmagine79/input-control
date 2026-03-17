import SwiftUI

@main
struct InputControlApp: App {
    @StateObject private var preferences: AppPreferences
    @StateObject private var deviceStore: AudioDeviceStore
    @StateObject private var launchAtLoginManager: LaunchAtLoginManager
    @StateObject private var themeManager: ThemeManager

    init() {
        let preferences = AppPreferences()
        let deviceStore = AudioDeviceStore(preferences: preferences)
        let launchAtLoginManager = LaunchAtLoginManager(preferences: preferences)
        _preferences = StateObject(wrappedValue: preferences)
        _deviceStore = StateObject(wrappedValue: deviceStore)
        _launchAtLoginManager = StateObject(wrappedValue: launchAtLoginManager)
        _themeManager = StateObject(wrappedValue: ThemeManager(preferences: preferences))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
                .fontDesign(.monospaced)
        } label: {
            MenuBarLabelView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
                .environmentObject(launchAtLoginManager)
        }
    }
}
