import SwiftUI

struct ExtrasView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var debugLogger = DebugLogger.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Health") {
                    NavigationLink(destination: InjuryTrackingView(apiClient: authViewModel.currentAPIClient)) {
                        HStack {
                            Image(systemName: "bandage.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Injury Tracker")
                                    .font(.headline)
                                Text("Log injuries and manage bodyparts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
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
