import Foundation

/// A Kalman filter implementation specifically designed for weight tracking
/// This filter models weight as a state with position (current weight) and velocity (rate of change)
class WeightKalmanFilter {
    
    // MARK: - State Variables
    
    /// State vector: [weight, weight_rate]
    private var state: [Double] = [0.0, 0.0]
    
    /// Covariance matrix P (2x2)
    private var covariance: [[Double]] = [[0.0, 0.0], [0.0, 0.0]]
    
    /// Process noise covariance Q (2x2)
    private let processNoise: [[Double]]
    
    /// Measurement noise covariance R (1x1)
    private let measurementNoise: Double
    
    /// State transition matrix F (2x2)
    private var stateTransition: [[Double]] = [[1.0, 0.0], [0.0, 1.0]]
    
    /// Measurement matrix H (1x2) - we only measure weight, not rate
    private let measurementMatrix: [Double] = [1.0, 0.0]
    
    // MARK: - Initialization
    
    /// Initialize the Kalman filter with noise parameters
    /// - Parameters:
    ///   - processNoise: How much we expect the weight and rate to vary naturally
    ///   - measurementNoise: How much noise we expect in our weight measurements
    ///   - initialWeight: Starting weight estimate
    ///   - initialRate: Starting rate estimate (lbs/day)
    init(processNoise: Double = 0.1, measurementNoise: Double = 0.5, initialWeight: Double = 170.0, initialRate: Double = 0.0) {
        // Process noise affects both weight and rate
        self.processNoise = [
            [processNoise * 0.1, 0.0],  // Weight process noise (smaller)
            [0.0, processNoise]         // Rate process noise (larger)
        ]
        
        self.measurementNoise = measurementNoise
        
        // Initialize state
        self.state = [initialWeight, initialRate]
        
        // Initialize covariance with some uncertainty
        self.covariance = [
            [1.0, 0.0],   // Initial weight uncertainty
            [0.0, 10.0]   // Initial rate uncertainty (higher)
        ]
    }
    
    // MARK: - Kalman Filter Operations
    
    /// Update the filter with a new weight measurement
    /// - Parameters:
    ///   - measurement: The measured weight
    ///   - deltaTime: Time since last measurement (in days)
    func update(measurement: Double, deltaTime: Double) {
        // Update state transition matrix with time delta
        stateTransition[0][1] = deltaTime  // weight += rate * deltaTime
        
        // Predict step
        predict(deltaTime: deltaTime)
        
        // Update step
        correct(measurement: measurement)
    }
    
    /// Predict the next state based on the current state and time delta
    private func predict(deltaTime: Double) {
        // Predict state: x = F * x
        let newWeight = state[0] + state[1] * deltaTime
        let newRate = state[1] // Rate stays the same in prediction
        
        state = [newWeight, newRate]
        
        // Predict covariance: P = F * P * F' + Q
        let f = stateTransition
        let ft = transpose(f)
        let fpf = multiply(multiply(f, covariance), ft)
        covariance = add(fpf, processNoise)
    }
    
    /// Correct the prediction with the measurement
    private func correct(measurement: Double) {
        // Calculate innovation (residual)
        let predicted = state[0] * measurementMatrix[0] + state[1] * measurementMatrix[1]
        let innovation = measurement - predicted
        
        // Calculate innovation covariance S = H * P * H' + R
        let h = measurementMatrix
        let hp = multiplyVector(h, covariance)
        let hph = dotProduct(hp, h)
        let innovationCovariance = hph + measurementNoise
        
        // Calculate Kalman gain K = P * H' / S
        let ph = [
            covariance[0][0] * h[0] + covariance[0][1] * h[1],
            covariance[1][0] * h[0] + covariance[1][1] * h[1]
        ]
        let kalmanGain = [
            ph[0] / innovationCovariance,
            ph[1] / innovationCovariance
        ]
        
        // Update state: x = x + K * innovation
        state[0] += kalmanGain[0] * innovation
        state[1] += kalmanGain[1] * innovation
        
        // Update covariance: P = (I - K * H) * P
        let kh = [
            [kalmanGain[0] * h[0], kalmanGain[0] * h[1]],
            [kalmanGain[1] * h[0], kalmanGain[1] * h[1]]
        ]
        let identity = [[1.0, 0.0], [0.0, 1.0]]
        let iMinusKh = subtract(identity, kh)
        covariance = multiply(iMinusKh, covariance)
    }
    
    // MARK: - Public Interface
    
    /// Get the current filtered weight estimate
    var filteredWeight: Double {
        return state[0]
    }
    
    /// Get the current weight change rate (lbs/day)
    var weightRate: Double {
        return state[1]
    }
    
    /// Get the current weight change rate per week
    var weeklyRate: Double {
        return state[1] * 7.0
    }
    
    /// Get the uncertainty in the weight estimate
    var weightUncertainty: Double {
        return sqrt(covariance[0][0])
    }
    
    /// Get the uncertainty in the rate estimate
    var rateUncertainty: Double {
        return sqrt(covariance[1][1])
    }
    
    /// Predict weight at a future time
    /// - Parameter daysAhead: Number of days into the future
    /// - Returns: Predicted weight
    func predictWeight(daysAhead: Double) -> Double {
        return state[0] + state[1] * daysAhead
    }
    
    /// Reset the filter with new initial conditions
    func reset(initialWeight: Double, initialRate: Double = 0.0) {
        state = [initialWeight, initialRate]
        covariance = [
            [1.0, 0.0],
            [0.0, 10.0]
        ]
    }
}

// MARK: - Matrix Operations

extension WeightKalmanFilter {
    
    /// Multiply two 2x2 matrices
    private func multiply(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        let rows = a.count
        let cols = b[0].count
        let inner = b.count
        
        var result = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
        
        for i in 0..<rows {
            for j in 0..<cols {
                for k in 0..<inner {
                    result[i][j] += a[i][k] * b[k][j]
                }
            }
        }
        
        return result
    }
    
    /// Multiply matrix by vector
    private func multiplyVector(_ vector: [Double], _ matrix: [[Double]]) -> [Double] {
        var result = [0.0, 0.0]
        for i in 0..<2 {
            for j in 0..<2 {
                result[i] += vector[j] * matrix[j][i]
            }
        }
        return result
    }
    
    /// Dot product of two vectors
    private func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        return a[0] * b[0] + a[1] * b[1]
    }
    
    /// Transpose a 2x2 matrix
    private func transpose(_ matrix: [[Double]]) -> [[Double]] {
        return [
            [matrix[0][0], matrix[1][0]],
            [matrix[0][1], matrix[1][1]]
        ]
    }
    
    /// Add two 2x2 matrices
    private func add(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        return [
            [a[0][0] + b[0][0], a[0][1] + b[0][1]],
            [a[1][0] + b[1][0], a[1][1] + b[1][1]]
        ]
    }
    
    /// Subtract two 2x2 matrices
    private func subtract(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        return [
            [a[0][0] - b[0][0], a[0][1] - b[0][1]],
            [a[1][0] - b[1][0], a[1][1] - b[1][1]]
        ]
    }
}

// MARK: - Weight Trend Analysis

struct WeightTrendAnalysis {
    let filteredWeights: [Double]
    let timestamps: [Double]
    let currentWeight: Double
    let currentRate: Double
    let weeklyRate: Double
    let confidence: Double
    
    /// Generate a line of best fit for charting
    func generateTrendLine(for timeRange: ClosedRange<Date>) -> [(Date, Double)] {
        let startTime = timeRange.lowerBound.timeIntervalSince1970
        let endTime = timeRange.upperBound.timeIntervalSince1970
        let duration = endTime - startTime
        
        let points: [(Date, Double)] = Array(stride(from: startTime, through: endTime, by: duration / 50)).map { timestamp in
            let daysFromNow = (timestamp - Date().timeIntervalSince1970) / 86400
            let predictedWeight = currentWeight + currentRate * daysFromNow
            return (Date(timeIntervalSince1970: timestamp), predictedWeight)
        }
        
        return points
    }
}

// MARK: - Utility Functions

extension WeightKalmanFilter {
    
    /// Process a series of weight entries and return analysis
    /// - Parameters:
    ///   - entries: Array of weight entries
    ///   - recencyWeightingFactor: How much to weight recent data (0.0 to 1.0)
    /// - Returns: Trend analysis results
    static func analyzeWeightData(_ entries: [WeightEntry], recencyWeightingFactor: Double = 0.7) -> WeightTrendAnalysis? {
        guard !entries.isEmpty else { return nil }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        
        // Initialize filter with first measurement
        let firstEntry = sortedEntries.first!
        let filter = WeightKalmanFilter(
            processNoise: 0.1,
            measurementNoise: 0.5,
            initialWeight: Double(firstEntry.weight),
            initialRate: 0.0
        )
        
        var filteredWeights: [Double] = []
        var timestamps: [Double] = []
        var lastTimestamp = firstEntry.timestamp
        
        // Process each measurement
        for entry in sortedEntries {
            let deltaTime = Double(entry.timestamp - lastTimestamp) / 86400.0 // Convert to days
            
            // Apply recency weighting - recent measurements get lower noise (higher confidence)
            let recencyFactor = calculateRecencyWeight(for: entry, in: sortedEntries, factor: recencyWeightingFactor)
            let adjustedNoise = 0.5 * (1.0 - recencyFactor) + 0.1 * recencyFactor
            
            // Create a new filter with adjusted noise for this measurement
            let adjustedFilter = WeightKalmanFilter(
                processNoise: 0.1,
                measurementNoise: adjustedNoise,
                initialWeight: filter.filteredWeight,
                initialRate: filter.weightRate
            )
            
            if deltaTime > 0 {
                adjustedFilter.update(measurement: Double(entry.weight), deltaTime: deltaTime)
            }
            
            filteredWeights.append(adjustedFilter.filteredWeight)
            timestamps.append(Double(entry.timestamp))
            lastTimestamp = entry.timestamp
        }
        
        // Calculate confidence based on data recency and amount
        let confidence = calculateConfidence(entries: sortedEntries)
        
        return WeightTrendAnalysis(
            filteredWeights: filteredWeights,
            timestamps: timestamps,
            currentWeight: filter.filteredWeight,
            currentRate: filter.weightRate,
            weeklyRate: filter.weeklyRate,
            confidence: confidence
        )
    }
    
    /// Calculate recency weight for a specific entry
    private static func calculateRecencyWeight(for entry: WeightEntry, in entries: [WeightEntry], factor: Double) -> Double {
        guard let lastEntry = entries.last else { return 0.0 }
        
        let totalTimeSpan = Double(lastEntry.timestamp - entries.first!.timestamp)
        let entryAge = Double(lastEntry.timestamp - entry.timestamp)
        
        if totalTimeSpan == 0 { return 1.0 }
        
        let relativeAge = entryAge / totalTimeSpan
        return pow(1.0 - relativeAge, factor)
    }
    
    /// Calculate confidence based on data quality
    private static func calculateConfidence(entries: [WeightEntry]) -> Double {
        let dataPoints = entries.count
        let timeSpan = Double(entries.last!.timestamp - entries.first!.timestamp) / 86400.0 // days
        
        // More data points and longer time span = higher confidence
        let dataPointScore = min(1.0, Double(dataPoints) / 30.0) // Normalize to 30 points
        let timeSpanScore = min(1.0, timeSpan / 90.0) // Normalize to 90 days
        
        return (dataPointScore + timeSpanScore) / 2.0
    }
}