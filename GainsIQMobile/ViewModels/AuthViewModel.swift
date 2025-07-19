import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    
    private let authService: AuthService
    private let apiClient: GainsIQAPIClient
    
    init() {
        self.authService = AuthService()
        self.apiClient = GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: Config.apiKey,
            authService: authService
        )
        
        setupAuthObserver()
        checkInitialAuthState()
    }
    
    // MARK: - Public Properties
    
    var currentAPIClient: GainsIQAPIClient {
        return apiClient
    }
    
    // MARK: - Public Methods
    
    func login(username: String, password: String) async throws {
        try await authService.login(username: username, password: password)
    }
    
    func logout() async {
        await authService.logout()
    }
    
    // MARK: - Private Methods
    
    private func setupAuthObserver() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }
    
    private func checkInitialAuthState() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Small delay to let auth service initialize
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Extensions

import Combine