import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var apiKey = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 10) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("GainsIQ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // API Key Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter API key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    Button(action: handleLogin) {
                        if isLoading {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save API Key")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isLoading || apiKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Login Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleLogin() {
        guard !apiKey.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authViewModel.login(apiKey: apiKey)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
