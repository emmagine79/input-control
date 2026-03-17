import AppKit
import Foundation

enum AppNavigation {
    @MainActor
    static func quit() {
        NSApplication.shared.terminate(nil)
    }

    @MainActor
    static func openSettings() {
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate()
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
