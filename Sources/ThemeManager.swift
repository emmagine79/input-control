import AppKit
import Combine
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    private var themeObservation: AnyCancellable?

    init(preferences: AppPreferences) {
        self.themeObservation = preferences.$theme.sink { [weak self] theme in
            self?.applyTheme(theme)
        }
    }

    private func applyTheme(_ theme: AppTheme) {
        guard let app = NSApp else { return }
        let appearance = theme.windowAppearance
        app.appearance = appearance
        for window in app.windows {
            window.appearance = appearance
        }
    }
}
