import AppIntents

// Expose app shortcuts so the intent appears in Shortcuts as “Log Weight”.
struct GainsIQAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWeightIntent(),
            phrases: [
                "Log weight in \(.applicationName)",
                "Add weight in \(.applicationName)",
                "Weigh in with \(.applicationName)"
            ],
            shortTitle: "Log Weight",
            systemImageName: "scalemass.fill"
        )
    }
}

