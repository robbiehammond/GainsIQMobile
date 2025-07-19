import Foundation
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    // selectedExercise is now managed by UserDefaultsManager
    @Published var workoutSets: [WorkoutSet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: ChartTimeRange = .sixMonths
    @Published var chartType: ProgressChartType = .estimated1RM
    
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
        loadUserDefaults()
    }
    
    // MARK: - Public Methods
    
    func loadExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let exerciseNames = try await apiClient.getExercises()
            exercises = exerciseNames.map { Exercise(name: $0) }
            
            // Auto-select first exercise if none selected
            if userDefaults.selectedExercise.isEmpty && !exercises.isEmpty {
                userDefaults.selectedExercise = exercises[0].name
            }
            
            // Load progress data for selected exercise (whether auto-selected or previously selected)
            if !userDefaults.selectedExercise.isEmpty {
                await loadProgressData()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadProgressData() async {
        guard !userDefaults.selectedExercise.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let endDate = Date()
            let startDate = endDate.addingTimeInterval(-selectedTimeRange.timeInterval)
            
            workoutSets = try await apiClient.getSetsByExercise(
                exerciseName: userDefaults.selectedExercise,
                start: startDate.unixTimestamp,
                end: endDate.unixTimestamp
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func changeExercise(_ exercise: String) {
        userDefaults.selectedExercise = exercise
        Task {
            await loadProgressData()
        }
    }
    
    func changeTimeRange(_ range: ChartTimeRange) {
        selectedTimeRange = range
        userDefaults.chartTimeRange = range
        Task {
            await loadProgressData()
        }
    }
    
    func changeChartType(_ type: ProgressChartType) {
        chartType = type
    }
    
    // MARK: - Private Methods
    
    private func loadUserDefaults() {
        // selectedExercise is now managed directly by UserDefaultsManager
        selectedTimeRange = userDefaults.chartTimeRange
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
        }.sortedByDate(ascending: true)
    }
    
    var groupedByDateSets: [Date: [WorkoutSet]] {
        return displaySets.groupedByDate()
    }
    
    var chartData: [ExerciseProgressDataPoint] {
        let sortedGroups = groupedByDateSets.keys.sorted()
        
        return sortedGroups.compactMap { date -> ExerciseProgressDataPoint? in
            let setsForDate = groupedByDateSets[date] ?? []
            guard !setsForDate.isEmpty else { return nil }
            
            let totalVolume = setsForDate.reduce(0.0) { total, set in
                if let reps = Int(set.reps) {
                    return total + Double((Double(set.weight) * Double(reps)))
                }
                return total
            }
            
            let maxWeight = setsForDate.max { $0.weight < $1.weight }?.weight ?? 0
            let averageWeight = setsForDate.averageWeight()
            
            // Calculate estimated 1RM using Brzycki formula from average weight and reps (matching original React code)
            let averageReps = setsForDate.averageReps()
            let estimated1RM = averageReps > 0 ? averageWeight / (1.0278 - 0.0278 * averageReps) : 0
            
            let isFromCuttingPhase = setsForDate.first?.isFromCuttingPhase ?? false
            
            return ExerciseProgressDataPoint(
                date: date,
                volume: Double(totalVolume),
                maxWeight: Double(maxWeight),
                averageWeight: Double(averageWeight),
                estimated1RM: Double(estimated1RM),
                setCount: setsForDate.count,
                isFromCuttingPhase: isFromCuttingPhase
            )
        }
    }
    
    var chartYAxisRange: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...100 }
        
        let values: [Double]
        switch chartType {
        case .maxWeight:
            values = chartData.map { $0.maxWeight }
        case .averageWeight:
            values = chartData.map { $0.averageWeight }
        case .estimated1RM:
            values = chartData.map { $0.estimated1RM }
        }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.1
        
        return (minValue - padding)...(maxValue + padding)
    }
    
    var chartTimeRange: ClosedRange<Date> {
        guard !chartData.isEmpty else {
            let now = Date()
            return now.addingTimeInterval(-selectedTimeRange.timeInterval)...now
        }
        
        let dates = chartData.map { $0.date }
        let minDate = dates.min() ?? Date()
        let maxDate = dates.max() ?? Date()
        
        return minDate...maxDate
    }
    
    var hasData: Bool {
        !workoutSets.isEmpty
    }
    
    var hasSelectedExercise: Bool {
        !userDefaults.selectedExercise.isEmpty
    }
    
    var weightDisplayUnit: String {
        userDefaults.weightUnit.abbreviation
    }
    
    var chartTitle: String {
        switch chartType {
        case .maxWeight:
            return "Max Weight Over Time"
        case .averageWeight:
            return "Average Weight Over Time"
        case .estimated1RM:
            return "Estimated 1RM Over Time"
        }
    }
    
    var chartYAxisLabel: String {
        switch chartType {
        case .maxWeight, .averageWeight, .estimated1RM:
            return "Weight (\(weightDisplayUnit))"
        }
    }
    
    var totalWorkouts: Int {
        groupedByDateSets.keys.count
    }
    
    var totalSets: Int {
        displaySets.count
    }
    
    var totalVolume: Float {
        displaySets.totalVolume()
    }
    
    var currentMaxWeight: Float {
        displaySets.maxWeight()
    }
    
    var progressSummary: String {
        guard !chartData.isEmpty, chartData.count >= 2 else { return "Not enough data" }
        
        let first = chartData.first!
        let last = chartData.last!
        
        let improvement: Double
        let label: String
        
        switch chartType {
        case .maxWeight:
            improvement = last.maxWeight - first.maxWeight
            label = "max weight"
        case .averageWeight:
            improvement = last.averageWeight - first.averageWeight
            label = "average weight"
        case .estimated1RM:
            improvement = last.estimated1RM - first.estimated1RM
            label = "estimated 1RM"
        }
        
        let sign = improvement >= 0 ? "+" : ""
        return String(format: "%@%.1f %@ %@", sign, improvement, label == "volume" ? weightDisplayUnit : weightDisplayUnit, label)
    }
}

// MARK: - Supporting Types

enum ProgressChartType: String, CaseIterable {
    case maxWeight = "Max Weight"
    case averageWeight = "Average Weight"
    case estimated1RM = "Estimated 1RM"
    
    var displayName: String {
        return rawValue
    }
}

struct ExerciseProgressDataPoint {
    let date: Date
    let volume: Double
    let maxWeight: Double
    let averageWeight: Double
    let estimated1RM: Double
    let setCount: Int
    let isFromCuttingPhase: Bool
}

// MARK: - Mock Data

extension ProgressViewModel {
    static let mock: ProgressViewModel = {
        let viewModel = ProgressViewModel()
        viewModel.exercises = Exercise.mockArray
        viewModel.userDefaults.selectedExercise = "Bench Press"
        viewModel.workoutSets = WorkoutSet.mockArray
        return viewModel
    }()
}
