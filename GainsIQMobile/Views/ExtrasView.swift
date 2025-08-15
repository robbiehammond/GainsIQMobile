import SwiftUI

struct ExtrasView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var debugLogger = DebugLogger.shared
    @State private var isRefreshingToken = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Developer Tools") {
                    NavigationLink(destination: DebugLogView()) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("API Debug Log")
                                    .font(.headline)
                                Text("View all API requests and responses")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if debugLogger.logs.count > 0 {
                                Text("\(debugLogger.logs.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Authentication") {
                    // Token refresh status
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Token Last Refreshed")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        if let lastRefresh = authViewModel.currentAuthService.lastTokenRefresh {
                            Text(lastRefresh, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Manual token refresh button
                    Button(action: {
                        Task {
                            isRefreshingToken = true
                            do {
                                try await authViewModel.refreshToken()
                            } catch {
                                // Handle error silently or show alert if needed
                            }
                            isRefreshingToken = false
                        }
                    }) {
                        HStack {
                            Image(systemName: isRefreshingToken ? "arrow.clockwise" : "arrow.clockwise.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                                .rotationEffect(.degrees(isRefreshingToken ? 360 : 0))
                                .animation(isRefreshingToken ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshingToken)
                            
                            Text("Refresh Token")
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isRefreshingToken)
                }
                
                Section("Account") {
                    Button(action: {
                        Task {
                            await authViewModel.logout()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Logout")
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Extras")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ExtrasView()
        .environmentObject(AuthViewModel())
}