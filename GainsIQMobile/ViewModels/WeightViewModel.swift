import Foundation
import SwiftUI

@MainActor
class WeightViewModel: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    @Published var weightTrend: WeightTrend?
    @Published var currentWeight: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingSuccessMessage = false
    @Published var successMessage: String = ""
    @Published var selectedTimeRange: ChartTimeRange = .sixMonths
    
    private let apiClient: GainsIQAPIClient
    private let userDefaults = UserDefaultsManager.shared
    
    init(apiClient: GainsIQAPIClient? = nil) {
        self.apiClient = apiClient ?? GainsIQAPIClient(
            baseURL: Constants.API.defaultBaseURL,
            apiKey: Constants.API.Headers.apiKey
        )
        loadUserDefaults()
    }
    
    // MARK: - Public Methods
    
    func loadWeights() async {
        isLoading = true
        errorMessage = nil
        
        do {
            weightEntries = try await apiClient.getWeights()
            try await loadWeightTrend()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logWeight() async {
        guard !currentWeight.isEmpty,
              let weightValue = Float(currentWeight) else {
            errorMessage = "Please enter a valid weight"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let weightInPounds = convertToPounds(weightValue)
            try await apiClient.logWeight(weightInPounds)
            
            successMessage = "Weight logged successfully!"
            showingSuccessMessage = true
            
            // Clear form
            currentWeight = ""
            
            // Refresh data
            await loadWeights()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteRecentWeight() async {
        guard !weightEntries.isEmpty else {
            errorMessage = "No weights to delete"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let message = try await apiClient.deleteRecentWeight()
            successMessage = message
            showingSuccessMessage = true
            
            // Refresh data
            await loadWeights()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func changeTimeRange(_ range: ChartTimeRange) {
        selectedTimeRange = range
        userDefaults.chartTimeRange = range
    }
    
    // MARK: - Private Methods
    
    private func loadUserDefaults() {
        selectedTimeRange = userDefaults.chartTimeRange
    }
    
    private func loadWeightTrend() async throws {
        do {
            weightTrend = try await apiClient.getWeightTrend()
        } catch {
            // Weight trend is optional - don't fail if it's not available
            weightTrend = nil
        }
    }
    
    private func convertToPounds(_ weight: Float) -> Float {
        return userDefaults.convertWeight(weight, from: userDefaults.weightUnit, to: .pounds)
    }
    
    private func convertFromPounds(_ weight: Float) -> Float {
        return userDefaults.convertWeight(weight, from: .pounds, to: userDefaults.weightUnit)
    }
    
    // MARK: - Computed Properties
    
    var canSubmit: Bool {
        !currentWeight.isEmpty && !isLoading
    }
    
    var weightDisplayUnit: String {
        userDefaults.weightUnit.abbreviation
    }
    
    var displayWeightEntries: [WeightEntry] {
        let converted = weightEntries.map { entry in
            WeightEntry(
                timestamp: entry.timestamp,
                weight: convertFromPounds(entry.weight)
            )
        }
        
        // Filter by time range
        let cutoffDate = Date().addingTimeInterval(-selectedTimeRange.timeInterval)
        let cutoffTimestamp = cutoffDate.unixTimestamp
        
        return converted.filter { $0.timestamp >= cutoffTimestamp }
            .sortedByDate(ascending: true)
    }
    
    var recentEntries: [WeightEntry] {
        return displayWeightEntries.sortedByDate(ascending: false).prefix(5).map { $0 }
    }
    
    var currentWeightTrend: WeightTrend? {
        return weightTrend
    }
    
    var trendDescription: String {
        guard let trend = weightTrend else { return "No trend data available" }
        return trend.trendDescription
    }
    
    var weeklyChangeText: String {
        guard let trend = weightTrend else { return "No data" }
        return trend.formattedWeeklyChange
    }
    
    var chartData: [ChartDataPoint] {
        return displayWeightEntries.map { entry in
            ChartDataPoint(
                date: entry.date,
                value: Double(entry.weight),
                timestamp: entry.timestamp
            )
        }
    }
    
    var projectedTrendData: [ChartDataPoint] {
        guard let trend = weightTrend,
              let lastEntry = displayWeightEntries.last else { return [] }
        
        let now = Date()
        let oneMonthLater = now.addingTimeInterval(30 * 24 * 60 * 60)
        let projectedWeight = Double(lastEntry.weight) + (trend.slope * 30)
        
        return [
            ChartDataPoint(date: now, value: Double(lastEntry.weight), timestamp: now.unixTimestamp),
            ChartDataPoint(date: oneMonthLater, value: projectedWeight, timestamp: oneMonthLater.unixTimestamp)
        ]
    }
    
    var chartYAxisRange: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...100 }
        
        let values = chartData.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.1 // 10% padding
        
        return (minValue - padding)...(maxValue + padding)
    }
    
    var chartTimeRange: ClosedRange<Date> {
        guard !chartData.isEmpty else { 
            let now = Date()
            return now.addingTimeInterval(-30 * 24 * 60 * 60)...now
        }
        
        let dates = chartData.map { $0.date }
        let minDate = dates.min() ?? Date()
        let maxDate = dates.max() ?? Date()
        
        return minDate...maxDate
    }
    
    var hasData: Bool {
        !weightEntries.isEmpty
    }
    
    var averageWeight: Float {
        guard !displayWeightEntries.isEmpty else { return 0 }
        return displayWeightEntries.averageWeight()
    }
    
    var totalWeightChange: Float {
        guard !displayWeightEntries.isEmpty else { return 0 }
        return displayWeightEntries.weightChange()
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint {
    let date: Date
    let value: Double
    let timestamp: Int64
}

// MARK: - Mock Data

extension WeightViewModel {
    static let mock: WeightViewModel = {
        let viewModel = WeightViewModel()
        viewModel.weightEntries = WeightEntry.mockArray
        viewModel.weightTrend = WeightTrend.mock
        viewModel.currentWeight = "180.5"
        return viewModel
    }()
}
