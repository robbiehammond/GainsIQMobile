import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    @State private var selectedTab = 0
    
    init() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
            // Workout Tab
            WorkoutTrackingView(apiClient: authViewModel.currentAPIClient)
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }
                .tag(0)
            
            // History Tab
            HistoryView(apiClient: authViewModel.currentAPIClient)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            // Weight Tab
            WeightTrackingView(apiClient: authViewModel.currentAPIClient)
                .tabItem {
                    Label("Weight", systemImage: "scalemass.fill")
                }
                .tag(2)
            
            // Progress Tab
            ProgressChartsView(apiClient: authViewModel.currentAPIClient)
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            // Analysis Tab
            AnalysisView(apiClient: authViewModel.currentAPIClient)
                .tabItem {
                    Label("Analysis", systemImage: "brain.head.profile")
                }
                .tag(4)
            }
            .accentColor(.blue)
            .onAppear {
                userDefaults.loadSettings()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        Task {
                            await authViewModel.logout()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct ProgressPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .padding()
                
                Text("Progress Charts")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding()
                
                Text("Visualize your progress with detailed charts and analytics")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Coming Soon!")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}