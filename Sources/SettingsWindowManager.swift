import AppKit
import Combine
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    private var themeObservation: AnyCancellable?

    init(preferences: AppPreferences) {
        applyTheme(preferences.theme)
        self.themeObservation = preferences.$theme.sink { [weak self] theme in
            self?.applyTheme(theme)
        }
    }

    private func applyTheme(_ theme: AppTheme) {
        let appearance = theme.windowAppearance
        NSApp.appearance = appearance
        for window in NSApp.windows {
            window.appearance = appearance
        }
    }
}
