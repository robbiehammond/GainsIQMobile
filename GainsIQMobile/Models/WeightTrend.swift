import Foundation

struct WeightTrend: Codable {
    let date: String
    let slope: Double
    
    enum CodingKeys: String, CodingKey {
        case date
        case slope
    }
    
    init(date: String, slope: Double) {
        self.date = date
        self.slope = slope
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        slope = try container.decode(Double.self, forKey: .slope)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(slope, forKey: .slope)
    }
}

extension WeightTrend {
    var weeklyChange: Double {
        slope * 7
    }
    
    var monthlyChange: Double {
        slope * 30
    }
    
    var isGaining: Bool {
        slope > 0
    }
    
    var isLosing: Bool {
        slope < 0
    }
    
    var isStable: Bool {
        abs(slope) < 0.1
    }
    
    var formattedWeeklyChange: String {
        let prefix = weeklyChange >= 0 ? "+" : ""
        return String(format: "%@%.2f lbs/week", prefix, weeklyChange)
    }
    
    var trendDescription: String {
        if isStable {
            return "Maintaining weight"
        } else if isGaining {
            return "Gaining weight"
        } else {
            return "Losing weight"
        }
    }
}

extension WeightTrend {
    static let mock = WeightTrend(
        date: "2024-01-15",
        slope: 0.2
    )
    
    static let mockLosing = WeightTrend(
        date: "2024-01-15",
        slope: -0.3
    )
    
    static let mockStable = WeightTrend(
        date: "2024-01-15",
        slope: 0.05
    )
}