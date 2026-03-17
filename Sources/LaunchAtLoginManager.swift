import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published var errorMessage: String?

    private let preferences: AppPreferences
    private let fileManager: FileManager

    init(preferences: AppPreferences, fileManager: FileManager = .default) {
        self.preferences = preferences
        self.fileManager = fileManager
        refreshStatus()
    }

    func setEnabled(_ enabled: Bool) {
        do {
            try updateLaunchBehavior(enabled: enabled)
            preferences.launchAtLogin = enabled
            errorMessage = nil
        } catch {
            preferences.launchAtLogin = currentStatus()
            errorMessage = error.localizedDescription
        }
    }

    func refreshStatus() {
        preferences.launchAtLogin = currentStatus()
    }

    private func updateLaunchBehavior(enabled: Bool) throws {
        if #available(macOS 13, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                    try? removeLaunchAgent()
                }
                return
            } catch {
                if enabled {
                    try writeLaunchAgent()
                } else {
                    try removeLaunchAgent()
                }
                return
            }
        }

        if enabled {
            try writeLaunchAgent()
        } else {
            try removeLaunchAgent()
        }
    }

    private func currentStatus() -> Bool {
        if #available(macOS 13, *) {
            if SMAppService.mainApp.status == .enabled {
                return true
            }
        }

        return fileManager.fileExists(atPath: launchAgentURL.path)
    }

    private var launchAgentURL: URL {
        let libraryURL = fileManager.homeDirectoryForCurrentUser.appending(path: "Library/LaunchAgents")
        return libraryURL.appending(path: "\(resolvedBundleIdentifier).launchagent.plist")
    }

    private var resolvedBundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.antigravity.inputcontrol"
    }

    private var launchTargetPath: String {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            return bundleURL.path
        }

        return Bundle.main.executableURL?.path ?? bundleURL.path
    }

    private func writeLaunchAgent() throws {
        let launchAgentsDirectory = launchAgentURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: launchAgentsDirectory, withIntermediateDirectories: true)

        let payload: [String: Any] = [
            "Label": "\(resolvedBundleIdentifier).launchagent",
            "ProgramArguments": [
                "/usr/bin/open",
                "-a",
                launchTargetPath
            ],
            "RunAtLoad": true
        ]

        let plistData = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)
        try plistData.write(to: launchAgentURL, options: .atomic)
    }

    private func removeLaunchAgent() throws {
        if fileManager.fileExists(atPath: launchAgentURL.path) {
            try fileManager.removeItem(at: launchAgentURL)
        }
    }
}
