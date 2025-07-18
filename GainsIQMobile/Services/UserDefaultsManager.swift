import Foundation

class UserDefaultsManager: ObservableObject {
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let weightUnit = "weightUnit"
        static let cuttingState = "cuttingState"
        static let apiURL = "apiURL"
        static let apiKey = "apiKey"
        static let lastSyncDate = "lastSyncDate"
        static let selectedExercise = "selectedExercise"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let enableNotifications = "enableNotifications"
        static let enableHaptics = "enableHaptics"
        static let chartTimeRange = "chartTimeRange"
    }
    
    // MARK: - Weight Unit
    
    @Published var weightUnit: WeightUnit = .pounds {
        didSet {
            userDefaults.set(weightUnit.rawValue, forKey: Keys.weightUnit)
        }
    }
    
    // MARK: - Cutting State
    
    @Published var cuttingState: CuttingState = .bulking {
        didSet {
            userDefaults.set(cuttingState.rawValue, forKey: Keys.cuttingState)
        }
    }
    
    // MARK: - API Configuration
    
    var apiURL: String {
        get {
            return userDefaults.string(forKey: Keys.apiURL) ?? ""
        }
        set {
            userDefaults.set(newValue, forKey: Keys.apiURL)
        }
    }
    
    var apiKey: String {
        get {
            return userDefaults.string(forKey: Keys.apiKey) ?? ""
        }
        set {
            userDefaults.set(newValue, forKey: Keys.apiKey)
        }
    }
    
    // MARK: - Last Sync Date
    
    var lastSyncDate: Date? {
        get {
            return userDefaults.object(forKey: Keys.lastSyncDate) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: Keys.lastSyncDate)
        }
    }
    
    // MARK: - Selected Exercise
    
    @Published var selectedExercise: String = "" {
        didSet {
            userDefaults.set(selectedExercise, forKey: Keys.selectedExercise)
        }
    }
    
    // MARK: - Onboarding
    
    var hasSeenOnboarding: Bool {
        get {
            return userDefaults.bool(forKey: Keys.hasSeenOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasSeenOnboarding)
        }
    }
    
    // MARK: - App Settings
    
    @Published var enableNotifications: Bool = true {
        didSet {
            userDefaults.set(enableNotifications, forKey: Keys.enableNotifications)
        }
    }
    
    @Published var enableHaptics: Bool = true {
        didSet {
            userDefaults.set(enableHaptics, forKey: Keys.enableHaptics)
        }
    }
    
    @Published var chartTimeRange: ChartTimeRange = .sixMonths {
        didSet {
            userDefaults.set(chartTimeRange.rawValue, forKey: Keys.chartTimeRange)
        }
    }
    
    // MARK: - Initialization
    
    func loadSettings() {
        if let weightUnitString = userDefaults.string(forKey: Keys.weightUnit),
           let weightUnit = WeightUnit(rawValue: weightUnitString) {
            self.weightUnit = weightUnit
        }
        
        if let cuttingStateString = userDefaults.string(forKey: Keys.cuttingState),
           let cuttingState = CuttingState(rawValue: cuttingStateString) {
            self.cuttingState = cuttingState
        }
        
        self.selectedExercise = userDefaults.string(forKey: Keys.selectedExercise) ?? ""
        
        self.enableNotifications = userDefaults.bool(forKey: Keys.enableNotifications)
        self.enableHaptics = userDefaults.bool(forKey: Keys.enableHaptics)
        
        if let chartTimeRangeString = userDefaults.string(forKey: Keys.chartTimeRange),
           let chartTimeRange = ChartTimeRange(rawValue: chartTimeRangeString) {
            self.chartTimeRange = chartTimeRange
        }
    }
    
    // MARK: - Reset Settings
    
    func resetToDefaults() {
        userDefaults.removeObject(forKey: Keys.weightUnit)
        userDefaults.removeObject(forKey: Keys.cuttingState)
        userDefaults.removeObject(forKey: Keys.selectedExercise)
        userDefaults.removeObject(forKey: Keys.enableNotifications)
        userDefaults.removeObject(forKey: Keys.enableHaptics)
        userDefaults.removeObject(forKey: Keys.chartTimeRange)
        
        loadSettings()
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        userDefaults.synchronize()
    }
}

// MARK: - Enums

enum WeightUnit: String, CaseIterable {
    case pounds = "lbs"
    case kilograms = "kg"
    
    var displayName: String {
        switch self {
        case .pounds:
            return "Pounds (lbs)"
        case .kilograms:
            return "Kilograms (kg)"
        }
    }
    
    var abbreviation: String {
        return rawValue
    }
}

enum CuttingState: String, CaseIterable {
    case cutting = "CUTTING"
    case bulking = "BULKING"
    
    var displayName: String {
        switch self {
        case .cutting:
            return "Cutting"
        case .bulking:
            return "Bulking"
        }
    }
    
    var isCutting: Bool {
        return self == .cutting
    }
}

enum ChartTimeRange: String, CaseIterable {
    case oneWeek = "1week"
    case oneMonth = "1month"
    case threeMonths = "3months"
    case sixMonths = "6months"
    case oneYear = "1year"
    
    var displayName: String {
        switch self {
        case .oneWeek:
            return "Last Week"
        case .oneMonth:
            return "Last Month"
        case .threeMonths:
            return "Last 3 Months"
        case .sixMonths:
            return "Last 6 Months"
        case .oneYear:
            return "Last Year"
        }
    }
    
    // TODO: Mac builds get preprod, phone builds get prod
    var timeInterval: TimeInterval {
        switch self {
        case .oneWeek:
            return 7 * 24 * 60 * 60
        case .oneMonth:
            return 30 * 24 * 60 * 60
        case .threeMonths:
            return 90 * 24 * 60 * 60
        case .sixMonths:
            return 180 * 24 * 60 * 60
        case .oneYear:
            return 365 * 24 * 60 * 60
        }
    }
}

// MARK: - Weight Conversion Utilities

extension WeightUnit {
    func convert(_ weight: Float, to targetUnit: WeightUnit) -> Float {
        if self == targetUnit {
            return weight
        }
        
        switch (self, targetUnit) {
        case (.pounds, .kilograms):
            return weight * 0.453592
        case (.kilograms, .pounds):
            return weight / 0.453592
        default:
            return weight
        }
    }
}

extension UserDefaultsManager {
    func convertWeight(_ weight: Float, from sourceUnit: WeightUnit, to targetUnit: WeightUnit) -> Float {
        return sourceUnit.convert(weight, to: targetUnit)
    }
    
    func formatWeight(_ weight: Float, unit: WeightUnit? = nil) -> String {
        let displayUnit = unit ?? self.weightUnit
        return String(format: "%.1f %@", weight, displayUnit.abbreviation)
    }
}
