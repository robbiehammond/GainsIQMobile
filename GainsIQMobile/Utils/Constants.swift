import Foundation
import SwiftUI

struct Constants {
    
    // MARK: - App Info
    
    struct App {
        static let name = "GainsIQ"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let identifier = Bundle.main.bundleIdentifier ?? "com.gainsiq.mobile"
    }
    
    // MARK: - API Configuration
    
    struct API {
        static let defaultBaseURL = Environment.current.apiBaseURL
        static let timeout: TimeInterval = 30.0
        static let retryCount = 3
        static let retryDelay: TimeInterval = 1.0
        
        struct Headers {
            static let contentType = "Content-Type"
            static let apiKey = Config.apiKey
            static let userAgent = "User-Agent"
        }
        
        struct ContentTypes {
            static let json = "application/json"
        }
    }
    
    // MARK: - UI Constants
    
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Float = 0.1
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let animationDuration: TimeInterval = 0.3
        static let hapticDelay: TimeInterval = 0.1
        
        struct Padding {
            static let tiny: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }
        
        struct Spacing {
            static let tiny: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }
        
        struct FontSize {
            static let caption: CGFloat = 12
            static let body: CGFloat = 16
            static let headline: CGFloat = 18
            static let title: CGFloat = 24
            static let largeTitle: CGFloat = 32
        }
    }
    
    // MARK: - Chart Constants
    
    struct Chart {
        static let defaultHeight: CGFloat = 300
        static let compactHeight: CGFloat = 200
        static let minDataPoints = 2
        static let maxDataPoints = 1000
        static let animationDuration: TimeInterval = 0.5
        
        struct Colors {
            static let primary = Color.blue
            static let secondary = Color.green
            static let accent = Color.purple
            static let cutting = Color.red
            static let bulking = Color.blue
            static let gridLines = Color.gray.opacity(0.3)
        }
    }
    
    // MARK: - Workout Constants
    
    struct Workout {
        static let minWeight: Float = 0.5
        static let maxWeight: Float = 2000.0
        static let weightIncrement: Float = 0.5
        static let minReps = 1
        static let maxReps = 100
        static let defaultSets = 1
        
        struct RepOptions {
            static let below5 = "5 or below"
            static let above25 = "25 or more"
            static let standardRange = Array(6...25).map { "\($0)" }
            static let allOptions = [below5] + standardRange + [above25]
        }
    }
    
    // MARK: - Weight Constants
    
    struct Weight {
        static let minWeight: Float = 50.0  // 50 lbs or kg
        static let maxWeight: Float = 1000.0 // 1000 lbs or kg
        static let weightIncrement: Float = 0.1
        static let poundsToKilograms: Float = 0.453592
        static let kilogramsToPounds: Float = 2.20462
        
        struct Trend {
            static let minDataPoints = 2
            static let analysisWindowDays = 14
            static let stableThreshold = 0.1 // lbs per day
        }
    }
    
    // MARK: - Sync Constants
    
    struct Sync {
        static let maxRetries = 3
        static let retryDelaySeconds: TimeInterval = 2.0
        static let backgroundSyncInterval: TimeInterval = 300 // 5 minutes
        static let forceRefreshInterval: TimeInterval = 3600 // 1 hour
    }
    
    // MARK: - Cache Constants
    
    struct Cache {
        static let maxCacheSize = 50 * 1024 * 1024 // 50MB
        static let maxCacheAge: TimeInterval = 86400 // 24 hours
        static let exercisesCacheKey = "exercises_cache"
        static let setsCacheKey = "sets_cache"
        static let weightsCacheKey = "weights_cache"
        static let analysisCacheKey = "analysis_cache"
    }
    
    // MARK: - Validation Constants
    
    struct Validation {
        static let minExerciseNameLength = 2
        static let maxExerciseNameLength = 50
        static let minPasswordLength = 6
        static let maxPasswordLength = 128
        
        struct Regex {
            static let email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            static let url = "^https?://[\\w\\-]+(\\.[\\w\\-]+)+[/#?]?.*$"
        }
    }
    
    // MARK: - Notification Constants
    
    struct Notifications {
        static let workoutReminderIdentifier = "workout_reminder"
        static let weightLogReminderIdentifier = "weight_log_reminder"
        static let analysisReadyIdentifier = "analysis_ready"
        
        struct UserInfo {
            static let workoutId = "workoutId"
            static let exerciseName = "exerciseName"
            static let analysisId = "analysisId"
        }
    }
    
    // MARK: - Accessibility
    
    struct Accessibility {
        static let workoutSetLabel = "Workout Set"
        static let weightEntryLabel = "Weight Entry"
        static let chartLabel = "Progress Chart"
        static let deleteButtonLabel = "Delete"
        static let editButtonLabel = "Edit"
        static let saveButtonLabel = "Save"
        static let cancelButtonLabel = "Cancel"
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        static let enableNotifications = true
        static let enableHaptics = true
        static let enableCharts = true
        static let enableExport = true
        static let enableDarkMode = true
        static let enableOfflineMode = true
        static let enableDebugMode = false
        
        #if DEBUG
        static let enableLogging = true
        #else
        static let enableLogging = false
        #endif
    }
    
    // MARK: - Error Messages
    
    struct ErrorMessages {
        static let networkError = "Unable to connect to server. Please check your internet connection."
        static let invalidData = "Invalid data received from server."
        static let unauthorized = "You are not authorized to perform this action."
        static let notFound = "The requested resource was not found."
        static let serverError = "Server error occurred. Please try again later."
        static let unknownError = "An unknown error occurred."
        static let validationError = "Please check your input and try again."
        static let offlineError = "This feature requires an internet connection."
        static let cacheError = "Unable to load cached data."
    }
    
    // MARK: - Success Messages
    
    struct SuccessMessages {
        static let workoutLogged = "Workout logged successfully!"
        static let weightLogged = "Weight logged successfully!"
        static let exerciseAdded = "Exercise added successfully!"
        static let exerciseDeleted = "Exercise deleted successfully!"
        static let setDeleted = "Set deleted successfully!"
        static let setEdited = "Set updated successfully!"
        static let dataExported = "Data exported successfully!"
        static let settingsSaved = "Settings saved successfully!"
    }
}

// MARK: - Environment Configuration

extension Constants {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
        
        var apiBaseURL: String {
            switch self {
            case .development:
                return Config.developmentURL
            case .staging:
                return Config.developmentURL // Using development URL for staging
            case .production:
                return Config.baseURL
            }
        }
        
        var enableLogging: Bool {
            switch self {
            case .development, .staging:
                return true
            case .production:
                return false
            }
        }
    }
}
