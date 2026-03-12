import SwiftUI

struct MenuBarLabelView: View {
    @EnvironmentObject private var deviceStore: AudioDeviceStore
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        if preferences.showsDeviceNameInMenuBar, let currentDevice = deviceStore.currentDevice {
            Label(currentDevice.shortName, systemImage: "mic.fill")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        } else {
            Image(systemName: "mic.fill")
        }
    }
}
