import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowManager: ObservableObject {
    private let deviceStore: AudioDeviceStore
    private let preferences: AppPreferences
    private let launchAtLoginManager: LaunchAtLoginManager
    private var windowController: NSWindowController?
    private var themeObservation: AnyCancellable?

    init(
        deviceStore: AudioDeviceStore,
        preferences: AppPreferences,
        launchAtLoginManager: LaunchAtLoginManager
    ) {
        self.deviceStore = deviceStore
        self.preferences = preferences
        self.launchAtLoginManager = launchAtLoginManager
        self.themeObservation = preferences.$theme.sink { [weak self] _ in
            self?.applyThemeToWindow()
        }
    }

    func show() {
        let controller = windowController ?? makeWindowController()
        windowController = controller

        if let hostingController = controller.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = makeRootView()
        }

        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        applyTheme(to: controller.window)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindowController() -> NSWindowController {
        let hostingController = NSHostingController(rootView: makeRootView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 560, height: 480))
        window.minSize = NSSize(width: 520, height: 420)
        window.isReleasedWhenClosed = false
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbarStyle = .preference
        window.backgroundColor = .clear
        window.center()
        applyTheme(to: window)

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

    private func applyThemeToWindow() {
        applyTheme(to: windowController?.window)
    }

    private func applyTheme(to window: NSWindow?) {
        window?.appearance = preferences.theme.windowAppearance
    }
}
