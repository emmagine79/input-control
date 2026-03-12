import SwiftUI

@main
struct InputControlApp: App {
    @StateObject private var preferences: AppPreferences
    @StateObject private var deviceStore: AudioDeviceStore
    @StateObject private var launchAtLoginManager: LaunchAtLoginManager
    @StateObject private var settingsWindowManager: SettingsWindowManager

    init() {
        let preferences = AppPreferences()
        let deviceStore = AudioDeviceStore(preferences: preferences)
        let launchAtLoginManager = LaunchAtLoginManager(preferences: preferences)
        _preferences = StateObject(wrappedValue: preferences)
        _deviceStore = StateObject(wrappedValue: deviceStore)
        _launchAtLoginManager = StateObject(wrappedValue: launchAtLoginManager)
        _settingsWindowManager = StateObject(
            wrappedValue: SettingsWindowManager(
                deviceStore: deviceStore,
                preferences: preferences,
                launchAtLoginManager: launchAtLoginManager
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
                .environmentObject(settingsWindowManager)
                .fontDesign(.monospaced)
                .preferredColorScheme(preferences.theme.resolvedColorScheme(for: NSApp.effectiveAppearance))
        } label: {
            MenuBarLabelView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
                .fontDesign(.monospaced)
        }
        .menuBarExtraStyle(.window)
    }
}
