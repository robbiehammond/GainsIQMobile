import Foundation
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var workoutSets: [WorkoutSet] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage = false
    @Published var successMessage: String = ""
    @Published var editingSet: WorkoutSet?
    @Published var showingEditSheet = false
    
    // Edit form fields
    @Published var editReps: String = ""
    @Published var editWeight: String = ""
    
    private let apiClient: GainsIQAPIClient
    private let userDefaults = UserDefaultsManager.shared
    
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
    
    func loadSetsForDate(_ date: Date) async {
        isLoading = true
        errorMessage = nil
        selectedDate = date
        
        do {
            workoutSets = try await apiClient.getSetsForDate(date)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadSetsForDateRange(start: Date, end: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            workoutSets = try await apiClient.getSetsForDateRange(start: start, end: end)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteSet(_ set: WorkoutSet) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.deleteSet(workoutId: set.workoutId, timestamp: set.timestamp)
            
            // Remove from local array
            workoutSets.removeAll { $0.workoutId == set.workoutId && $0.timestamp == set.timestamp }
            
            successMessage = "Set deleted successfully!"
            showingSuccessMessage = true
            
            // Refresh data to get updated set numbers
            await loadSetsForDate(selectedDate)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func startEditing(_ set: WorkoutSet) {
        editingSet = set
        editReps = set.reps
        editWeight = String(convertFromPounds(set.weight))
        showingEditSheet = true
    }
    
    func saveEdit() async {
        guard let set = editingSet,
              !editReps.isEmpty,
              !editWeight.isEmpty,
              let weightValue = Float(editWeight) else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let weightInPounds = convertToPounds(weightValue)
            
            try await apiClient.editSet(
                workoutId: set.workoutId,
                timestamp: set.timestamp,
                reps: editReps,
                weight: weightInPounds
            )
            
            // Update local array
            if let index = workoutSets.firstIndex(where: { $0.workoutId == set.workoutId && $0.timestamp == set.timestamp }) {
                workoutSets[index] = WorkoutSet(
                    workoutId: set.workoutId,
                    timestamp: set.timestamp,
                    exercise: set.exercise,
                    reps: editReps,
                    sets: set.sets,
                    weight: weightInPounds,
                    weightModulation: set.weightModulation
                )
            }
            
            successMessage = "Set updated successfully!"
            showingSuccessMessage = true
            
            // Clear edit state
            editingSet = nil
            showingEditSheet = false
            editReps = ""
            editWeight = ""
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func cancelEdit() {
        editingSet = nil
        showingEditSheet = false
        editReps = ""
        editWeight = ""
    }
    
    // MARK: - Private Methods
    
    private func convertToPounds(_ weight: Float) -> Float {
        return userDefaults.convertWeight(weight, from: userDefaults.weightUnit, to: .pounds)
    }
    
    private func convertFromPounds(_ weight: Float) -> Float {
        return userDefaults.convertWeight(weight, from: .pounds, to: userDefaults.weightUnit)
    }
    
    // MARK: - Computed Properties
    
    var displaySets: [WorkoutSet] {
        return workoutSets.map { set in
            WorkoutSet(
                workoutId: set.workoutId,
                timestamp: set.timestamp,
                exercise: set.exercise,
                reps: set.reps,
                sets: set.sets,
                weight: convertFromPounds(set.weight),
                weightModulation: set.weightModulation
            )
        }.sortedByDate(ascending: false)
    }
    
    var groupedSets: [Date: [WorkoutSet]] {
        return displaySets.groupedByDate()
    }
    
    var selectedDateSets: [WorkoutSet] {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        return displaySets.filter { set in
            let setDate = Calendar.current.startOfDay(for: set.date)
            return setDate == startOfDay
        }
    }
    
    var hasData: Bool {
        !workoutSets.isEmpty
    }
    
    var hasDataForSelectedDate: Bool {
        !selectedDateSets.isEmpty
    }
    
    var weightDisplayUnit: String {
        userDefaults.weightUnit.abbreviation
    }
    
    var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    var totalSetsCount: Int {
        workoutSets.count
    }
    
    var uniqueExercisesCount: Int {
        Set(workoutSets.map { $0.exercise }).count
    }
    
    var totalVolume: Float {
        return displaySets.totalVolume()
    }
    
    var canSaveEdit: Bool {
        !editReps.isEmpty && !editWeight.isEmpty && !isLoading
    }
}

// MARK: - Mock Data

extension HistoryViewModel {
    static let mock: HistoryViewModel = {
        let viewModel = HistoryViewModel()
        viewModel.workoutSets = WorkoutSet.mockArray
        viewModel.selectedDate = Date()
        return viewModel
    }()
}
