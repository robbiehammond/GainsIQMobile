import Foundation
import SwiftUI

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var analysis: Analysis?
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage = false
    @Published var successMessage: String = ""
    
    private let apiClient: GainsIQAPIClient
    
    init(apiClient: GainsIQAPIClient? = nil) {
        if let apiClient = apiClient {
            self.apiClient = apiClient
        } else {
            // Create a temporary AuthService for standalone usage
            let authService = AuthService()
            self.apiClient = GainsIQAPIClient(
                baseURL: Constants.API.defaultBaseURL,
                apiKey: Constants.API.Headers.apiKey,
                authService: authService
            )
        }
    }
    
    // MARK: - Public Methods
    
    func loadAnalysis() async {
        isLoading = true
        errorMessage = nil
        
        do {
            analysis = try await apiClient.getAnalysis()
        } catch {
            // Analysis might not exist yet
            if case APIError.notFound = error {
                analysis = nil
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func generateAnalysis() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            let message = try await apiClient.generateAnalysis()
            successMessage = message
            showingSuccessMessage = true
            
            // Wait a moment then try to load the analysis
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await loadAnalysis()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func refreshAnalysis() async {
        await loadAnalysis()
    }
    
    // MARK: - Computed Properties
    
    var hasAnalysis: Bool {
        analysis != nil
    }
    
    var analysisContent: String {
        analysis?.content ?? ""
    }
    
    var analysisDate: String {
        guard let analysis = analysis else { return "" }
        return analysis.formattedDate
    }
    
    var isAnalysisRecent: Bool {
        analysis?.isRecent ?? false
    }
    
    var canGenerate: Bool {
        !isGenerating && !isLoading
    }
    
    var statusText: String {
        if isGenerating {
            return "Generating analysis..."
        } else if isLoading {
            return "Loading analysis..."
        } else if hasAnalysis {
            return "Analysis ready"
        } else {
            return "No analysis available"
        }
    }
    
    var analysisAge: String {
        guard let analysis = analysis else { return "" }
        return analysis.date.timeAgo()
    }
    
    // MARK: - Analysis Parsing
    
    var analysisLines: [String] {
        return analysisContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    var hasSections: Bool {
        return analysisLines.contains { line in
            line.hasPrefix("##") || line.hasPrefix("**") || line.contains(":")
        }
    }
    
    // Simple parsing for common analysis formats
    var analysisStructure: AnalysisStructure {
        let lines = analysisLines
        var sections: [AnalysisSection] = []
        var currentSection: AnalysisSection?
        
        for line in lines {
            if line.hasPrefix("##") || line.contains(":") {
                // Save previous section
                if let section = currentSection {
                    sections.append(section)
                }
                
                // Start new section
                let title = line.replacingOccurrences(of: "##", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespaces)
                currentSection = AnalysisSection(title: title, content: [])
            } else {
                // Add content to current section
                if currentSection != nil {
                    currentSection?.content.append(line)
                } else {
                    // No section yet, create a general one
                    if sections.isEmpty {
                        currentSection = AnalysisSection(title: "Overview", content: [line])
                    } else {
                        currentSection?.content.append(line)
                    }
                }
            }
        }
        
        // Add last section
        if let section = currentSection {
            sections.append(section)
        }
        
        // If no sections were created, put everything in overview
        if sections.isEmpty && !lines.isEmpty {
            sections.append(AnalysisSection(title: "Analysis", content: lines))
        }
        
        return AnalysisStructure(sections: sections)
    }
}

// MARK: - Analysis Structure Models

struct AnalysisStructure {
    let sections: [AnalysisSection]
    
    var isEmpty: Bool {
        sections.allSatisfy { $0.content.isEmpty }
    }
}

struct AnalysisSection {
    let title: String
    var content: [String]
    
    var isEmpty: Bool {
        content.isEmpty
    }
    
    var contentText: String {
        content.joined(separator: "\n")
    }
}

// MARK: - Mock Data

extension AnalysisViewModel {
    static let mock: AnalysisViewModel = {
        let viewModel = AnalysisViewModel()
        viewModel.analysis = Analysis.mock
        return viewModel
    }()
}
