import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private var apiClient: GainsIQAPIClient {
        GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: UserDefaultsManager.shared.apiKey.isEmpty ? Config.apiKey : UserDefaultsManager.shared.apiKey
        )
    }
    
    init() {
        // Consider user authenticated if an API key exists in settings
        isAuthenticated = !UserDefaultsManager.shared.apiKey.isEmpty || !Config.apiKey.isEmpty
    }
    
    // MARK: - Public Properties
    
    var currentAPIClient: GainsIQAPIClient {
        return apiClient
    }
    
    // MARK: - Public Methods
    
    func login(apiKey: String) async throws {
        // Persist the API key and mark as authenticated
        UserDefaultsManager.shared.apiKey = apiKey
        isAuthenticated = true
    }
    
    func logout() async {
        UserDefaultsManager.shared.apiKey = ""
        isAuthenticated = false
    }
}
