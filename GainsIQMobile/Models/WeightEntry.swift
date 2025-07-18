import Foundation

struct WeightEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Int64
    let weight: Float
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case weight
    }
    
    init(timestamp: Int64, weight: Float) {
        self.timestamp = timestamp
        self.weight = weight
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle timestamp as string from backend
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        timestamp = Int64(timestampString) ?? 0
        
        // Handle weight as string from backend
        let weightString = try container.decode(String.self, forKey: .weight)
        weight = Float(weightString) ?? 0.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(weight, forKey: .weight)
    }
}

extension WeightEntry {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedWeight: String {
        String(format: "%.1f lbs", weight)
    }
}

extension WeightEntry {
    static let mock = WeightEntry(
        timestamp: Int64(Date().timeIntervalSince1970),
        weight: 180.5
    )
    
    static let mockArray = [
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970), weight: 180.5),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 86400), weight: 181.0),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 172800), weight: 180.8),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 259200), weight: 181.2),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 345600), weight: 181.5),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 432000), weight: 180.9),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 518400), weight: 181.8),
        WeightEntry(timestamp: Int64(Date().timeIntervalSince1970 - 604800), weight: 182.1)
    ]
}

