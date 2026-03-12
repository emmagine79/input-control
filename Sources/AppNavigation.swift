import AppKit
import Foundation

enum AppNavigation {
    @MainActor
    static func quit() {
        NSApplication.shared.terminate(nil)
    }
}
