import Foundation
import AppIntents

// App Intent to log a weight entry. This can be exposed as an App Shortcut
// and triggered by the iPhone Action Button via the Shortcuts app.
struct LogWeightIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Weight"
    static var description = IntentDescription(
        "Log your current body weight to GainsIQ.",
        categoryName: "Logging"
    )

    @Parameter(title: "Weight", requestValueDialog: "What is your weight?")
    var weight: Double

    func perform() async throws -> some ProvidesDialog {
        // Resolve API client using the same configuration as the app
        let apiKey = UserDefaultsManager.shared.apiKey.isEmpty ? Config.apiKey : UserDefaultsManager.shared.apiKey
        let client = GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: apiKey
        )

        // Convert from user's preferred unit to pounds to match backend
        let preferredUnit = UserDefaultsManager.shared.weightUnit
        let weightFloat = Float(weight)
        let weightInPounds: Float
        switch preferredUnit {
        case .pounds:
            weightInPounds = weightFloat
        case .kilograms:
            weightInPounds = UserDefaultsManager.shared.convertWeight(weightFloat, from: .kilograms, to: .pounds)
        }

        try await client.logWeight(weightInPounds)

        // Confirm to the user in their preferred unit
        let formatted = UserDefaultsManager.shared.formatWeight(Float(weight), unit: preferredUnit)
        return .result(dialog: "Logged \(formatted)")
    }
}

