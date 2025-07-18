import Foundation
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var selectedExercise: String = ""
    @Published var reps: String = ""
    @Published var weight: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage = false
    @Published var successMessage: String = ""
    @Published var showingAddExercise = false
    @Published var newExerciseName: String = ""
    @Published var searchText: String = ""
    
    private let apiClient: GainsIQAPIClient
    private let userDefaults = UserDefaultsManager.shared
    
    // MARK: - Computed Properties
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init(apiClient: GainsIQAPIClient? = nil) {
        self.apiClient = apiClient ?? GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: Constants.API.Headers.apiKey
        )
        loadUserDefaults()
    }
    
    // MARK: - Public Methods
    
    func loadExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let exerciseNames = try await apiClient.getExercises()
            exercises = exerciseNames.map { Exercise(name: $0) }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logWorkout() async {
        guard !selectedExercise.isEmpty,
              !reps.isEmpty,
              !weight.isEmpty,
              let weightValue = Float(weight) else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let isCutting = userDefaults.cuttingState.isCutting
            let weightInPounds = convertToPounds(weightValue)
            
            try await apiClient.logWorkoutSet(
                exercise: selectedExercise,
                reps: reps,
                weight: weightInPounds,
                isCutting: isCutting
            )
            
            successMessage = "Workout logged successfully!"
            showingSuccessMessage = true
            
            // Clear form but keep exercise selected
            reps = ""
            weight = ""
            
            // Save selected exercise to user defaults
            userDefaults.selectedExercise = selectedExercise
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addExercise() async {
        guard !newExerciseName.trimmed.isEmpty else {
            errorMessage = "Exercise name cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.addExercise(newExerciseName.trimmed)
            
            // Add to local list
            exercises.append(Exercise(name: newExerciseName.trimmed))
            
            // Select the new exercise
            selectedExercise = newExerciseName.trimmed
            
            // Clear form and close sheet
            newExerciseName = ""
            showingAddExercise = false
            
            successMessage = "Exercise added successfully!"
            showingSuccessMessage = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func popLastSet() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let message = try await apiClient.popLastSet()
            successMessage = message
            showingSuccessMessage = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func generateAnalysis() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let message = try await apiClient.generateAnalysis()
            successMessage = message
            showingSuccessMessage = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func loadUserDefaults() {
        selectedExercise = userDefaults.selectedExercise
    }
    
    private func convertToPounds(_ weight: Float) -> Float {
        return userDefaults.convertWeight(weight, from: userDefaults.weightUnit, to: .pounds)
    }
    
    // MARK: - Computed Properties
    
    var canSubmit: Bool {
        !selectedExercise.isEmpty && !reps.isEmpty && !weight.isEmpty && !isLoading
    }
    
    var weightDisplayUnit: String {
        userDefaults.weightUnit.abbreviation
    }
    
    var isInCuttingPhase: Bool {
        userDefaults.cuttingState.isCutting
    }
    
    var repOptions: [String] {
        return Constants.Workout.RepOptions.allOptions
    }
}

// MARK: - Mock Data

extension WorkoutViewModel {
    static let mock: WorkoutViewModel = {
        let viewModel = WorkoutViewModel()
        viewModel.exercises = Exercise.mockArray
        viewModel.selectedExercise = "Bench Press"
        viewModel.reps = "8"
        viewModel.weight = "185"
        return viewModel
    }()
}
