import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowManager: ObservableObject {
    private static let frameAutosaveName = "InputControlSettingsWindow"
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
        applyThemeToApp()
        self.themeObservation = preferences.$theme.sink { [weak self] _ in
            self?.applyThemeToApp()
            self?.applyThemeToWindow()
            if let controller = self?.windowController {
                self?.updateRootView(in: controller)
            }
        }
    }

    func show() {
        let controller = windowController ?? makeWindowController()
        windowController = controller

        updateRootView(in: controller)

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
        window.setFrameAutosaveName(Self.frameAutosaveName)
        window.center()
        applyTheme(to: window)

        return NSWindowController(window: window)
    }

    private func makeRootView() -> AnyView {
        return AnyView(
            SettingsView()
                .environmentObject(deviceStore)
                .environmentObject(preferences)
                .environmentObject(launchAtLoginManager)
                .fontDesign(.monospaced)
        )
    }

    private func updateRootView(in controller: NSWindowController) {
        if let hostingController = controller.contentViewController as? NSHostingController<AnyView> {
            hostingController.rootView = makeRootView()
        }
    }

    private func applyThemeToWindow() {
        applyTheme(to: windowController?.window)
    }

    private func applyThemeToApp() {
        let appearance = preferences.theme.windowAppearance
        NSApp.appearance = appearance
        for window in NSApp.windows {
            window.appearance = appearance
        }
    }

    private func applyTheme(to window: NSWindow?) {
        window?.appearance = preferences.theme.windowAppearance
    }
}
