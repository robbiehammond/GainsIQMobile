import Foundation

// MARK: - Request Models

struct AddExerciseRequest: Codable {
    let exerciseName: String
    
    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
    }
}

struct DeleteExerciseRequest: Codable {
    let exerciseName: String
    
    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
    }
}

struct LogSetRequest: Codable {
    let exercise: String
    let reps: String
    let sets: Int
    let weight: Float
    let isCutting: Bool?
    let timestamp: Int64?
    
    enum CodingKeys: String, CodingKey {
        case exercise
        case reps
        case sets
        case weight
        case isCutting
        case timestamp
    }
}

struct EditSetRequest: Codable {
    let workoutId: String
    let timestamp: Int64
    let reps: String?
    let sets: Int?
    let weight: Float?
    
    enum CodingKeys: String, CodingKey {
        case workoutId
        case timestamp
        case reps
        case sets
        case weight
    }
}

struct DeleteSetRequest: Codable {
    let workoutId: String
    let timestamp: Int64
    
    enum CodingKeys: String, CodingKey {
        case workoutId
        case timestamp
    }
}

struct LogWeightRequest: Codable {
    let weight: Float
    
    enum CodingKeys: String, CodingKey {
        case weight
    }
}

// MARK: - Injury & Bodypart Request Models

struct InjuryRequest: Codable {
    let timestamp: Int64?
    let location: String
    let details: String?
    let active: Bool?
}

struct UpdateInjuryActiveRequest: Codable {
    let timestamp: Int64
    let active: Bool
}

struct AddBodypartRequest: Codable {
    let location: String
}

struct DeleteBodypartRequest: Codable {
    let location: String
}

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let idToken: String
    let refreshToken: String
    let expiresIn: Int32
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

// MARK: - Response Models

struct APIResponse<T: Codable>: Codable {
    let data: T?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case data
        case message
        case error
    }
}

struct MessageResponse: Codable {
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case message
    }
}

struct SuccessResponse: Codable {
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case success
    }
}

// MARK: - API Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case serverError(String)
    case unauthorized
    case notFound
    case badRequest(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response format"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized: Invalid API key"
        case .notFound:
            return "Resource not found"
        case .badRequest(let message):
            return "Bad request: \(message)"
        }
    }
}

// MARK: - Utility Extensions

extension LogSetRequest {
    init(exercise: String, reps: String, weight: Float, isCutting: Bool, timestamp: Int64? = nil) {
        self.exercise = exercise
        self.reps = reps
        self.sets = 1 // Default to 1 set as per the web app
        self.weight = weight
        self.isCutting = isCutting
        self.timestamp = timestamp
    }
}

extension EditSetRequest {
    init(workoutId: String, timestamp: Int64, reps: String?, weight: Float?) {
        self.workoutId = workoutId
        self.timestamp = timestamp
        self.reps = reps
        self.sets = nil // Don't modify sets in edit
        self.weight = weight
    }
}
