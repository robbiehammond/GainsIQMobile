import SwiftUI

struct AnalysisView: View {
    @StateObject private var viewModel: AnalysisViewModel
    @StateObject private var userDefaults = UserDefaultsManager.shared
    
    init(apiClient: GainsIQAPIClient) {
        self._viewModel = StateObject(wrappedValue: AnalysisViewModel(apiClient: apiClient))
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: Constants.UI.Spacing.large) {
                    // Header section
                    headerSection
                    
                    // Generate analysis section
                    if !viewModel.hasAnalysis {
                        generateAnalysisSection
                    }
                    
                    // Analysis content
                    if viewModel.hasAnalysis {
                        analysisContentSection
                    }
                    
                    // Loading state
                    if viewModel.isLoading || viewModel.isGenerating {
                        loadingSection
                    }
                }
                .padding(Constants.UI.Padding.medium)
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadAnalysis()
        }
        .refreshable {
            await viewModel.refreshAnalysis()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        .alert("Success", isPresented: $viewModel.showingSuccessMessage) {
            Button("OK") { }
        } message: {
            Text(viewModel.successMessage)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: Constants.UI.Spacing.small) {
            Text("AI Workout Analysis")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Text("Status:")
                    .foregroundColor(.secondary)
                
                Text(viewModel.statusText)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.hasAnalysis ? .green : .orange)
                
                Spacer()
                
                if viewModel.hasAnalysis {
                    Text("Updated: \(viewModel.analysisAge)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .padding(.horizontal)
        }
    }
    
    private var generateAnalysisSection: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            VStack(spacing: Constants.UI.Spacing.small) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
                
                Text("Generate Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Get personalized insights and recommendations based on your workout data")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.generateAnalysis()
                    if userDefaults.enableHaptics {
                        successHaptic()
                    }
                }
            }) {
                HStack {
                    if viewModel.isGenerating {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    
                    Text(viewModel.isGenerating ? "Generating..." : "Generate Analysis")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canGenerate ? Color.purple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(Constants.UI.cornerRadius)
            }
            .disabled(!viewModel.canGenerate)
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var analysisContentSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            // Header with regenerate button
            HStack {
                Text("Your Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.generateAnalysis()
                    }
                }) {
                    HStack {
                        if viewModel.isGenerating {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Regenerate")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, Constants.UI.Padding.small)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(Constants.UI.cornerRadius / 2)
                }
                .disabled(!viewModel.canGenerate)
            }
            
            // Analysis date
            Text("Generated: \(viewModel.analysisDate)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Analysis content
            if viewModel.analysisStructure.isEmpty {
                // Simple text display
                Text(viewModel.analysisContent)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            } else {
                // Structured display
                LazyVStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
                    ForEach(Array(viewModel.analysisStructure.sections.enumerated()), id: \.offset) { index, section in
                        analysisSection(section: section)
                    }
                }
            }
        }
        .padding(Constants.UI.Padding.medium)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private func analysisSection(section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            if !section.title.isEmpty {
                Text(section.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            ForEach(Array(section.content.enumerated()), id: \.offset) { index, content in
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }
        }
        .padding(Constants.UI.Padding.small)
        .background(Color(.systemBackground))
        .cornerRadius(Constants.UI.cornerRadius / 2)
    }
    
    private var loadingSection: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            SwiftUI.ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text(viewModel.isGenerating ? "Generating analysis..." : "Loading analysis...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if viewModel.isGenerating {
                Text("This may take a few minutes")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.UI.Padding.large)
        .background(Color(.systemGray6))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// MARK: - Preview

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView(apiClient: GainsIQAPIClient(
            baseURL: Config.baseURL,
            apiKey: Config.apiKey,
            authService: AuthService()
        ))
    }
}