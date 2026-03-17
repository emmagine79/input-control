import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var deviceStore: AudioDeviceStore
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var settingsWindowManager: SettingsWindowManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let errorMessage = deviceStore.errorMessage {
                errorCard(errorMessage)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    currentInputCard
                    availableInputsSection
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 320)

            footer
        }
        .padding(18)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .fontDesign(.monospaced)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Input Control")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))

            Text(deviceStore.currentDevice?.name ?? "No input selected")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var currentInputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Current Input")

            Group {
                if let currentDevice = deviceStore.currentDevice {
                    deviceRow(for: currentDevice, isCurrent: true)
                } else {
                    Text("No active input device is available.")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardBackground(highlighted: false))
                }
            }
        }
    }

    private var availableInputsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Available Inputs")

            ForEach(deviceStore.devices) { device in
                Button {
                    deviceStore.selectInput(device)
                } label: {
                    deviceRow(for: device, isCurrent: device.id == deviceStore.currentInputID)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Divider()

            HStack(spacing: 10) {
                Button("Refresh") {
                    deviceStore.refresh()
                }

                Spacer()

                Button("Settings…") {
                    settingsWindowManager.show()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("Quit Input Control") {
                AppNavigation.quit()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
    }

    private func errorCard(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(highlighted: false))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }

    private func deviceRow(for device: AudioDevice, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: isCurrent ? "checkmark.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if preferences.preferredInputUID == device.id {
                        badge("Preferred")
                    }
                }

                Text(device.transportLabel)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(highlighted: isCurrent))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func badge(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.accentColor.opacity(0.14)))
            .foregroundStyle(Color.accentColor)
    }

    private func cardBackground(highlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(highlighted ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(highlighted ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
            )
    }
}
