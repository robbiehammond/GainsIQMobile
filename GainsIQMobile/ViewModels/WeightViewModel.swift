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
        // Try to get trend from API first (for backwards compatibility)
        do {
            weightTrend = try await apiClient.getWeightTrend()
        } catch {
            // Fall back to local Kalman filter analysis if API trend not available
            weightTrend = calculateLocalWeightTrend()
        }
    }
    
    /// Calculate weight trend using local Kalman filter analysis
    private func calculateLocalWeightTrend() -> WeightTrend? {
        guard !weightEntries.isEmpty else { return nil }
        
        // Use Kalman filter to analyze the weight data
        guard let analysis = WeightKalmanFilter.analyzeWeightData(weightEntries, recencyWeightingFactor: 0.7) else {
            return nil
        }
        
        return WeightTrend.from(analysis: analysis)
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
    
    /// Get future projection data only (from now onwards)
    var projectedTrendData: [ChartDataPoint] {
        guard let trend = weightTrend,
              !displayWeightEntries.isEmpty else { return [] }
        
        // Generate only future projection (from now onwards)
        let now = Date()
        let futureEndTime = now.addingTimeInterval(30 * 24 * 60 * 60) // 30 days ahead
        let futureRange = now...futureEndTime
        
        // If we have Kalman analysis, use it for projection
        if let analysis = WeightKalmanFilter.analyzeWeightData(weightEntries, recencyWeightingFactor: 0.7) {
            let trendPoints = analysis.generateTrendLine(for: futureRange)
            return trendPoints.map { (date, weight) in
                ChartDataPoint(date: date, value: weight, timestamp: date.unixTimestamp)
            }
        } else {
            // Fallback to simple linear projection
            let currentWeight = trend.filteredWeight != 0.0 ? trend.filteredWeight : Double(displayWeightEntries.last?.weight ?? 0)
            let projectedWeight = currentWeight + (trend.weeklyChange * 4.33) // 4.33 weeks in a month
            
            return [
                ChartDataPoint(date: now, value: currentWeight, timestamp: now.unixTimestamp),
                ChartDataPoint(date: futureEndTime, value: projectedWeight, timestamp: futureEndTime.unixTimestamp)
            ]
        }
    }
    
    /// Get filtered weight data for smoother charting (historical data only)
    var filteredChartData: [ChartDataPoint] {
        guard let analysis = WeightKalmanFilter.analyzeWeightData(displayWeightEntries, recencyWeightingFactor: 0.7) else {
            return []
        }
        
        let basePoints = zip(analysis.filteredWeights, analysis.timestamps).map { (weight, timestamp) in
            ChartDataPoint(
                date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                value: weight,
                timestamp: Int64(timestamp)
            )
        }.filter { dataPoint in
            // Filter to selected time range and only show historical data (not future)
            let cutoffDate = Date().addingTimeInterval(-selectedTimeRange.timeInterval)
            let now = Date()
            return dataPoint.date >= cutoffDate && dataPoint.date <= now
        }
        
        // Add interpolated points for smoother visual line
        return interpolatePoints(basePoints)
    }
    
    /// Interpolate between data points for smoother line visualization
    private func interpolatePoints(_ points: [ChartDataPoint]) -> [ChartDataPoint] {
        guard points.count >= 2 else { return points }
        
        var smoothedPoints: [ChartDataPoint] = []
        
        for i in 0..<points.count - 1 {
            let currentPoint = points[i]
            let nextPoint = points[i + 1]
            
            // Add the current point
            smoothedPoints.append(currentPoint)
            
            // Add interpolated points between current and next
            let timeDiff = nextPoint.date.timeIntervalSince1970 - currentPoint.date.timeIntervalSince1970
            let valueDiff = nextPoint.value - currentPoint.value
            
            // Add 2 intermediate points for smoothness
            for j in 1...2 {
                let ratio = Double(j) / 3.0
                let interpolatedTime = currentPoint.date.timeIntervalSince1970 + timeDiff * ratio
                let interpolatedValue = currentPoint.value + valueDiff * ratio
                
                smoothedPoints.append(ChartDataPoint(
                    date: Date(timeIntervalSince1970: interpolatedTime),
                    value: interpolatedValue,
                    timestamp: Int64(interpolatedTime)
                ))
            }
        }
        
        // Add the last point
        if let lastPoint = points.last {
            smoothedPoints.append(lastPoint)
        }
        
        return smoothedPoints
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
