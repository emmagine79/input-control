import AppKit
import SwiftUI

@MainActor
final class SettingsWindowManager: ObservableObject {
    private let deviceStore: AudioDeviceStore
    private let preferences: AppPreferences
    private let launchAtLoginManager: LaunchAtLoginManager
    private var windowController: NSWindowController?

    init(
        deviceStore: AudioDeviceStore,
        preferences: AppPreferences,
        launchAtLoginManager: LaunchAtLoginManager
    ) {
        self.deviceStore = deviceStore
        self.preferences = preferences
        self.launchAtLoginManager = launchAtLoginManager
    }

    func show() {
        let controller = windowController ?? makeWindowController()
        windowController = controller

        if let hostingController = controller.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = makeRootView()
        }

        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindowController() -> NSWindowController {
        let hostingController = NSHostingController(rootView: makeRootView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 520, height: 420))
        window.minSize = NSSize(width: 520, height: 420)
        window.isReleasedWhenClosed = false
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbarStyle = .preference
        window.center()

        return NSWindowController(window: window)
    }

    private func makeRootView() -> AnyView {
        AnyView(
            SettingsView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
                .environmentObject(launchAtLoginManager)
                .fontDesign(.monospaced)
        )
    }
}
