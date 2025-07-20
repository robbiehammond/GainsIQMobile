import Foundation

struct WeightTrend: Codable {
    let date: String
    let slope: Double
    let confidence: Double
    let filteredWeight: Double
    let weeklyRate: Double
    
    enum CodingKeys: String, CodingKey {
        case date
        case slope
        case confidence
        case filteredWeight
        case weeklyRate
    }
    
    init(date: String, slope: Double, confidence: Double = 0.5, filteredWeight: Double = 0.0, weeklyRate: Double = 0.0) {
        self.date = date
        self.slope = slope
        self.confidence = confidence
        self.filteredWeight = filteredWeight
        self.weeklyRate = weeklyRate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        slope = try container.decode(Double.self, forKey: .slope)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.5
        filteredWeight = try container.decodeIfPresent(Double.self, forKey: .filteredWeight) ?? 0.0
        weeklyRate = try container.decodeIfPresent(Double.self, forKey: .weeklyRate) ?? 0.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(slope, forKey: .slope)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(filteredWeight, forKey: .filteredWeight)
        try container.encode(weeklyRate, forKey: .weeklyRate)
    }
}

extension WeightTrend {
    var weeklyChange: Double {
        weeklyRate != 0.0 ? weeklyRate : slope * 7
    }
    
    var monthlyChange: Double {
        weeklyChange * 4.33 // More accurate than slope * 30
    }
    
    var isGaining: Bool {
        weeklyChange > 0.1
    }
    
    var isLosing: Bool {
        weeklyChange < -0.1
    }
    
    var isStable: Bool {
        abs(weeklyChange) <= 0.1
    }
    
    var formattedWeeklyChange: String {
        let prefix = weeklyChange >= 0 ? "+" : ""
        return String(format: "%@%.2f lbs/week", prefix, weeklyChange)
    }
    
    var trendDescription: String {
        let confidenceText = confidence > 0.7 ? "" : " (low confidence)"
        
        if isStable {
            return "Maintaining weight" + confidenceText
        } else if isGaining {
            return "Gaining weight" + confidenceText
        } else {
            return "Losing weight" + confidenceText
        }
    }
    
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0:
            return "High"
        case 0.6..<0.8:
            return "Medium"
        case 0.4..<0.6:
            return "Low"
        default:
            return "Very Low"
        }
    }
}

extension WeightTrend {
    static let mock = WeightTrend(
        date: "2024-01-15",
        slope: 0.2,
        confidence: 0.8,
        filteredWeight: 175.2,
        weeklyRate: 1.4
    )
    
    static let mockLosing = WeightTrend(
        date: "2024-01-15",
        slope: -0.3,
        confidence: 0.75,
        filteredWeight: 172.1,
        weeklyRate: -2.1
    )
    
    static let mockStable = WeightTrend(
        date: "2024-01-15",
        slope: 0.05,
        confidence: 0.9,
        filteredWeight: 174.8,
        weeklyRate: 0.05
    )
    
    /// Create a WeightTrend from EMA analysis
    static func from(emaAnalysis: WeightEMAAnalysis) -> WeightTrend {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return WeightTrend(
            date: dateFormatter.string(from: Date()),
            slope: emaAnalysis.slope,
            confidence: emaAnalysis.confidence,
            filteredWeight: emaAnalysis.currentWeight,
            weeklyRate: emaAnalysis.weeklyRate
        )
    }
}
