import Foundation

class GainsIQAPIClient: ObservableObject {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession
    private let authService: AuthService
    
    init(baseURL: String, apiKey: String, authService: AuthService) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.authService = authService
        self.session = URLSession.shared
    }
    
    // MARK: - Private Helper Methods
    
    private func createRequest(endpoint: String, method: HTTPMethod, body: Data? = nil, requiresAuth: Bool = true) async throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        if requiresAuth {
            let accessToken = try await authService.getValidAccessToken()
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest, expecting type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            case 400...499:
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    throw APIError.badRequest(errorMessage)
                }
                throw APIError.badRequest("Client error")
            case 500...599:
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("Server error")
            default:
                throw APIError.invalidResponse
            }
            
            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch {
            if error is APIError {
                throw error
            }
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Exercise Endpoints
    
    func getExercises() async throws -> [String] {
        let request = try await createRequest(endpoint: "/exercises", method: .GET)
        return try await performRequest(request, expecting: [String].self)
    }
    
    func addExercise(_ exerciseName: String) async throws {
        let requestBody = AddExerciseRequest(exerciseName: exerciseName)
        let bodyData = try JSONEncoder().encode(requestBody)
        let request = try await createRequest(endpoint: "/exercises", method: .POST, body: bodyData)
        let _: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
    }
    
    func deleteExercise(_ exerciseName: String) async throws {
        let requestBody = DeleteExerciseRequest(exerciseName: exerciseName)
        let bodyData = try JSONEncoder().encode(requestBody)
        let request = try await createRequest(endpoint: "/exercises", method: .DELETE, body: bodyData)
        let _: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
    }
    
    // MARK: - Set Endpoints
    
    func logWorkoutSet(_ setRequest: LogSetRequest) async throws {
        let bodyData = try JSONEncoder().encode(setRequest)
        let request = try await createRequest(endpoint: "/sets/log", method: .POST, body: bodyData)
        let _: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
    }
    
    func getLastMonthSets() async throws -> [WorkoutSet] {
        let request = try await createRequest(endpoint: "/sets/last_month", method: .GET)
        return try await performRequest(request, expecting: [WorkoutSet].self)
    }
    
    func getSets(start: Int64, end: Int64) async throws -> [WorkoutSet] {
        let endpoint = "/sets?start=\(start)&end=\(end)"
        let request = try await createRequest(endpoint: endpoint, method: .GET)
        return try await performRequest(request, expecting: [WorkoutSet].self)
    }
    
    func getSetsByExercise(exerciseName: String, start: Int64, end: Int64) async throws -> [WorkoutSet] {
        let encodedExercise = exerciseName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? exerciseName
        let endpoint = "/sets/by_exercise?exerciseName=\(encodedExercise)&start=\(start)&end=\(end)"
        let request = try await createRequest(endpoint: endpoint, method: .GET)
        return try await performRequest(request, expecting: [WorkoutSet].self)
    }
    
    func editSet(_ editRequest: EditSetRequest) async throws {
        let bodyData = try JSONEncoder().encode(editRequest)
        let request = try await createRequest(endpoint: "/sets/edit", method: .PUT, body: bodyData)
        let _: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
    }
    
    func deleteSet(workoutId: String, timestamp: Int64) async throws {
        let requestBody = DeleteSetRequest(workoutId: workoutId, timestamp: timestamp)
        let bodyData = try JSONEncoder().encode(requestBody)
        let request = try await createRequest(endpoint: "/sets", method: .DELETE, body: bodyData)
        let _: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
    }
    
    func popLastSet() async throws -> String {
        let request = try await createRequest(endpoint: "/sets/pop", method: .POST)
        let response: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
        return response.message
    }
    
    // MARK: - Weight Endpoints
    
    func logWeight(_ weight: Float) async throws {
        let requestBody = LogWeightRequest(weight: weight)
        let bodyData = try JSONEncoder().encode(requestBody)
        let request = try await createRequest(endpoint: "/weight", method: .POST, body: bodyData)
        let _: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
    }
    
    func getWeights() async throws -> [WeightEntry] {
        let request = try await createRequest(endpoint: "/weight", method: .GET)
        return try await performRequest(request, expecting: [WeightEntry].self)
    }
    
    func deleteRecentWeight() async throws -> String {
        let request = try await createRequest(endpoint: "/weight", method: .DELETE)
        let response: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
        return response.message
    }
    
    func getWeightTrend() async throws -> WeightTrend {
        let request = try await createRequest(endpoint: "/weight/trend", method: .GET)
        return try await performRequest(request, expecting: WeightTrend.self)
    }
    
    // MARK: - Analysis Endpoints
    
    func generateAnalysis() async throws -> String {
        let request = try await createRequest(endpoint: "/analysis", method: .POST)
        let response: MessageResponse = try await performRequest(request, expecting: MessageResponse.self)
        return response.message
    }
    
    func getAnalysis() async throws -> Analysis {
        let request = try await createRequest(endpoint: "/analysis", method: .GET)
        let response: AnalysisResponse = try await performRequest(request, expecting: AnalysisResponse.self)
        return response.toAnalysis()
    }
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Convenience Extensions

extension GainsIQAPIClient {
    
    func logWorkoutSet(exercise: String, reps: String, weight: Float, isCutting: Bool) async throws {
        let setRequest = LogSetRequest(exercise: exercise, reps: reps, weight: weight, isCutting: isCutting)
        try await logWorkoutSet(setRequest)
    }
    
    func editSet(workoutId: String, timestamp: Int64, reps: String?, weight: Float?) async throws {
        let editRequest = EditSetRequest(workoutId: workoutId, timestamp: timestamp, reps: reps, weight: weight)
        try await editSet(editRequest)
    }
    
    func getSetsForDate(_ date: Date) async throws -> [WorkoutSet] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let startTs = Int64(startOfDay.timeIntervalSince1970)
        let endTs = Int64(endOfDay.timeIntervalSince1970)
        
        return try await getSets(start: startTs, end: endTs)
    }
    
    func getSetsForDateRange(start: Date, end: Date) async throws -> [WorkoutSet] {
        let startTs = Int64(start.timeIntervalSince1970)
        let endTs = Int64(end.timeIntervalSince1970)
        
        return try await getSets(start: startTs, end: endTs)
    }
}