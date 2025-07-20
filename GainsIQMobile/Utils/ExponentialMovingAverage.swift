import Foundation

/// A simple exponential moving average implementation for weight tracking
/// More recent data points have exponentially more influence on the trend
class WeightExponentialMovingAverage {
    
    // MARK: - Configuration
    
    /// Alpha value for EMA calculation (0.0 to 1.0)
    /// Higher values = more weight on recent data
    /// Typical values: 0.1 (smooth) to 0.3 (responsive)
    private let alpha: Double
    
    // MARK: - State
    
    private var emaValue: Double?
    private var lastTimestamp: Int64?
    
    // MARK: - Initialization
    
    /// Initialize the EMA calculator
    /// - Parameter alpha: Smoothing factor (0.0 to 1.0). Higher = more responsive to recent changes
    init(alpha: Double = 0.2) {
        self.alpha = max(0.0, min(1.0, alpha)) // Clamp between 0 and 1
    }
    
    // MARK: - Public Methods
    
    /// Update the EMA with a new weight measurement
    /// - Parameters:
    ///   - weight: New weight measurement
    ///   - timestamp: Timestamp of the measurement
    func update(weight: Double, timestamp: Int64) {
        if let currentEma = emaValue {
            // EMA formula: EMA(t) = alpha * X(t) + (1 - alpha) * EMA(t-1)
            emaValue = alpha * weight + (1 - alpha) * currentEma
        } else {
            // First measurement becomes the initial EMA value
            emaValue = weight
        }
        
        lastTimestamp = timestamp
    }
    
    /// Get the current EMA value
    var currentEMA: Double? {
        return emaValue
    }
    
    /// Reset the EMA calculator
    func reset() {
        emaValue = nil
        lastTimestamp = nil
    }
}

// MARK: - Weight Trend Analysis with EMA

struct WeightEMAAnalysis {
    let smoothedWeights: [Double]
    let timestamps: [Int64]
    let currentWeight: Double
    let weeklyRate: Double
    let confidence: Double
    let slope: Double
    
    /// Generate a trend line for charting
    func generateTrendLine(for timeRange: ClosedRange<Date>) -> [(Date, Double)] {
        let startTime = timeRange.lowerBound.timeIntervalSince1970
        let endTime = timeRange.upperBound.timeIntervalSince1970
        let duration = endTime - startTime
        
        // Calculate daily rate from weekly rate
        let dailyRate = weeklyRate / 7.0
        
        let points: [(Date, Double)] = Array(stride(from: startTime, through: endTime, by: duration / 50)).map { timestamp in
            let daysFromNow = (timestamp - Date().timeIntervalSince1970) / 86400
            let predictedWeight = currentWeight + dailyRate * daysFromNow
            return (Date(timeIntervalSince1970: timestamp), predictedWeight)
        }
        
        return points
    }
}

// MARK: - Static Analysis Functions

extension WeightExponentialMovingAverage {
    
    /// Analyze weight data using exponential moving average
    /// - Parameters:
    ///   - entries: Array of weight entries
    ///   - alpha: Smoothing factor for EMA (higher = more responsive)
    /// - Returns: EMA analysis results
    static func analyzeWeightData(_ entries: [WeightEntry], alpha: Double = 0.2) -> WeightEMAAnalysis? {
        guard !entries.isEmpty else { return nil }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        
        // Calculate EMA for all data points
        let ema = WeightExponentialMovingAverage(alpha: alpha)
        var smoothedWeights: [Double] = []
        var timestamps: [Int64] = []
        
        for entry in sortedEntries {
            ema.update(weight: Double(entry.weight), timestamp: entry.timestamp)
            smoothedWeights.append(ema.currentEMA ?? Double(entry.weight))
            timestamps.append(entry.timestamp)
        }
        
        let currentWeight = ema.currentEMA ?? Double(sortedEntries.last?.weight ?? 0)
        
        // Calculate trend slope (change per day)
        let slope = calculateSlope(smoothedWeights: smoothedWeights, timestamps: timestamps)
        let weeklyRate = slope * 7.0
        
        // Calculate confidence based on data quality
        let confidence = calculateConfidence(entries: sortedEntries)
        
        return WeightEMAAnalysis(
            smoothedWeights: smoothedWeights,
            timestamps: timestamps,
            currentWeight: currentWeight,
            weeklyRate: weeklyRate,
            confidence: confidence,
            slope: slope
        )
    }
    
    /// Calculate the slope (trend) from smoothed data
    private static func calculateSlope(smoothedWeights: [Double], timestamps: [Int64]) -> Double {
        guard smoothedWeights.count >= 2 else { return 0.0 }
        
        // Use last 30% of data for trend calculation (focus on recent trend)
        let recentCount = max(2, Int(Double(smoothedWeights.count) * 0.3))
        let recentWeights = Array(smoothedWeights.suffix(recentCount))
        let recentTimestamps = Array(timestamps.suffix(recentCount))
        
        // Convert timestamps to days since first timestamp
        let firstTimestamp = recentTimestamps.first!
        let days = recentTimestamps.map { Double($0 - firstTimestamp) / 86400.0 }
        
        // Calculate linear regression slope
        let n = Double(recentWeights.count)
        let sumX = days.reduce(0, +)
        let sumY = recentWeights.reduce(0, +)
        let sumXY = zip(days, recentWeights).map(*).reduce(0, +)
        let sumXX = days.map { $0 * $0 }.reduce(0, +)
        
        let denominator = n * sumXX - sumX * sumX
        guard abs(denominator) > 1e-10 else { return 0.0 } // Avoid division by zero
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        return slope
    }
    
    /// Calculate confidence based on data quality and consistency
    private static func calculateConfidence(entries: [WeightEntry]) -> Double {
        let dataPoints = entries.count
        let timeSpan = Double(entries.last!.timestamp - entries.first!.timestamp) / 86400.0 // days
        
        // More data points and longer time span = higher confidence
        let dataPointScore = min(1.0, Double(dataPoints) / 20.0) // Normalize to 20 points
        let timeSpanScore = min(1.0, timeSpan / 60.0) // Normalize to 60 days
        
        // Calculate variance to assess consistency
        let weights = entries.map { Double($0.weight) }
        let mean = weights.reduce(0, +) / Double(weights.count)
        let variance = weights.map { pow($0 - mean, 2) }.reduce(0, +) / Double(weights.count)
        let consistencyScore = max(0.0, 1.0 - (variance / 100.0)) // Lower variance = higher consistency
        
        return (dataPointScore + timeSpanScore + consistencyScore) / 3.0
    }
}

// MARK: - Convenience Extensions

extension WeightEMAAnalysis {
    
    /// Get trend classification based on weekly rate
    var trendClassification: String {
        let absRate = abs(weeklyRate)
        
        if absRate < 0.5 {
            return "Stable"
        } else if weeklyRate > 0 {
            return absRate > 2.0 ? "Rapidly Gaining" : "Gaining"
        } else {
            return absRate > 2.0 ? "Rapidly Losing" : "Losing"
        }
    }
    
    /// Get confidence level description
    var confidenceLevel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.6..<0.8: return "Medium"
        case 0.4..<0.6: return "Low"
        default: return "Very Low"
        }
    }
    
    /// Get formatted weekly change string
    var formattedWeeklyChange: String {
        let sign = weeklyRate >= 0 ? "+" : ""
        return String(format: "%@%.1f lbs/week", sign, weeklyRate)
    }
}