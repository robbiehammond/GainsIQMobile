import Foundation
import Security

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAccessToken: String?
    
    private let keychainService = "com.gainsiq.mobile"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let idTokenKey = "id_token"
    private let tokenExpiryKey = "token_expiry"
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    
    func login(username: String, password: String) async throws -> AuthResponse {
        let loginRequest = LoginRequest(username: username, password: password)
        let bodyData = try JSONEncoder().encode(loginRequest)
        
        guard let url = URL(string: Constants.API.defaultBaseURL + "auth/login") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let responseBody = data.isEmpty ? nil : String(data: data, encoding: .utf8)
            DebugLogger.shared.logError(
                method: "POST",
                endpoint: "auth/login",
                fullURL: url.absoluteString,
                responseBody: responseBody,
                error: "Invalid response format - not HTTPURLResponse"
            )
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        case 400...499:
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorData["error"] {
                throw APIError.badRequest(errorMessage)
            }
            throw APIError.badRequest("Invalid credentials")
        default:
            let responseBody = data.isEmpty ? nil : String(data: data, encoding: .utf8)
            DebugLogger.shared.logError(
                method: "POST",
                endpoint: "auth/login",
                fullURL: url.absoluteString,
                responseBody: responseBody,
                statusCode: httpResponse.statusCode,
                error: "Invalid response format - unexpected status code \(httpResponse.statusCode)"
            )
            throw APIError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        try await storeTokens(authResponse)
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentAccessToken = authResponse.accessToken
        }
        
        return authResponse
    }
    
    func refreshAccessToken() async throws -> String {
        guard let refreshToken = getRefreshToken() else {
            throw APIError.unauthorized
        }
        
        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
        let bodyData = try JSONEncoder().encode(refreshRequest)
        
        guard let url = URL(string: Constants.API.defaultBaseURL + "auth/refresh") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let responseBody = data.isEmpty ? nil : String(data: data, encoding: .utf8)
            DebugLogger.shared.logError(
                method: "POST",
                endpoint: "auth/refresh",
                fullURL: url.absoluteString,
                responseBody: responseBody,
                error: "Invalid response format - not HTTPURLResponse"
            )
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            await logout()
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseBody = data.isEmpty ? nil : String(data: data, encoding: .utf8)
            DebugLogger.shared.logError(
                method: "POST",
                endpoint: "auth/refresh",
                fullURL: url.absoluteString,
                responseBody: responseBody,
                statusCode: httpResponse.statusCode,
                error: "Invalid response format - unexpected status code \(httpResponse.statusCode)"
            )
            throw APIError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        try await storeTokens(authResponse)
        
        DispatchQueue.main.async {
            self.currentAccessToken = authResponse.accessToken
        }
        
        return authResponse.accessToken
    }
    
    func logout() async {
        clearTokens()
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentAccessToken = nil
        }
    }
    
    func getValidAccessToken() async throws -> String {
        if let token = currentAccessToken, !isTokenExpired() {
            return token
        }
        
        return try await refreshAccessToken()
    }
    
    // MARK: - Private Methods
    
    private func checkAuthenticationStatus() {
        if let accessToken = getAccessToken(), !isTokenExpired() {
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentAccessToken = accessToken
            }
        } else if getRefreshToken() != nil {
            Task {
                do {
                    _ = try await refreshAccessToken()
                } catch {
                    await logout()
                }
            }
        }
    }
    
    private func storeTokens(_ authResponse: AuthResponse) async throws {
        let expiryTime = Date().addingTimeInterval(TimeInterval(authResponse.expiresIn))
        
        try storeInKeychain(key: accessTokenKey, value: authResponse.accessToken)
        try storeInKeychain(key: refreshTokenKey, value: authResponse.refreshToken)
        try storeInKeychain(key: idTokenKey, value: authResponse.idToken)
        try storeInKeychain(key: tokenExpiryKey, value: String(expiryTime.timeIntervalSince1970))
    }
    
    private func getAccessToken() -> String? {
        return getFromKeychain(key: accessTokenKey)
    }
    
    private func getRefreshToken() -> String? {
        return getFromKeychain(key: refreshTokenKey)
    }
    
    private func isTokenExpired() -> Bool {
        guard let expiryString = getFromKeychain(key: tokenExpiryKey),
              let expiryTime = Double(expiryString) else {
            return true
        }
        
        let expiryDate = Date(timeIntervalSince1970: expiryTime)
        return Date() >= expiryDate.addingTimeInterval(-300) // Refresh 5 minutes before expiry
    }
    
    private func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: refreshTokenKey)
        deleteFromKeychain(key: idTokenKey)
        deleteFromKeychain(key: tokenExpiryKey)
    }
    
    // MARK: - Keychain Helpers
    
    private func storeInKeychain(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw APIError.serverError("Failed to store token in keychain")
        }
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
