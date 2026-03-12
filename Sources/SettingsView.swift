import CoreAudio
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var deviceStore: AudioDeviceStore
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var launchAtLoginManager: LaunchAtLoginManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            hero

            Form {
                appearanceSection
                launchSection
                preferredInputSection
                menuBarSection
            }
            .formStyle(.grouped)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let errorMessage = launchAtLoginManager.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(
            minWidth: 520,
            idealWidth: 560,
            maxWidth: .infinity,
            minHeight: 420,
            idealHeight: 500,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(.regularMaterial)
        .fontDesign(.monospaced)
        .preferredColorScheme(preferences.theme.colorScheme)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input Control Settings")
                .font(.system(size: 26, weight: .semibold, design: .monospaced))

            Text("Keep your Mac on the input you actually want, even when other devices connect.")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $preferences.theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title)
                        .tag(theme)
                }
            }
            .pickerStyle(.menu)

            Text("Choose a fixed light or dark look, or let Input Control follow the current macOS appearance.")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var launchSection: some View {
        Section("Startup") {
            Toggle("Launch at login", isOn: Binding(
                get: { preferences.launchAtLogin },
                set: { launchAtLoginManager.setEnabled($0) }
            ))

            Text("For the most reliable login behavior, keep the built app in /Applications before turning this on.")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var preferredInputSection: some View {
        Section("Preferred Input") {
            Picker("Preferred input", selection: Binding(
                get: { preferences.preferredInputID },
                set: { preferences.preferredInputID = $0 }
            )) {
                Text("None")
                    .tag(AudioDeviceID?.none)

                ForEach(deviceStore.devices) { device in
                    Text(device.name)
                        .tag(AudioDeviceID?.some(device.id))
                }
            }

            Toggle("Automatically keep the preferred input active", isOn: $preferences.autoRestorePreferredInput)

            HStack {
                Button("Use current input") {
                    deviceStore.makeCurrentDevicePreferred()
                }
                .disabled(deviceStore.currentInputID == nil)

                Spacer()

                if let preferredInputID = preferences.preferredInputID,
                   let preferredDevice = deviceStore.devices.first(where: { $0.id == preferredInputID }) {
                    Text("Preferred: \(preferredDevice.name)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var menuBarSection: some View {
        Section("Menu Bar") {
            Toggle("Show the current input name in the menu bar", isOn: $preferences.showsDeviceNameInMenuBar)

            Text("Turn this off if you want a cleaner single-icon menu bar item.")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
