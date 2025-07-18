import Foundation

struct Analysis: Identifiable, Codable {
    let id = UUID()
    let timestamp: Int64
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case content = "analysis"
    }
    
    init(timestamp: Int64, content: String) {
        self.timestamp = timestamp
        self.content = content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Backend returns analysis differently - check if it's a simple string response
        if let analysisString = try? container.decode(String.self, forKey: .content) {
            content = analysisString
            timestamp = Int64(Date().timeIntervalSince1970) // Use current time if no timestamp
        } else {
            // Handle timestamp as string from backend if present
            let timestampString = try container.decode(String.self, forKey: .timestamp)
            timestamp = Int64(timestampString) ?? Int64(Date().timeIntervalSince1970)
            content = try container.decode(String.self, forKey: .content)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(content, forKey: .content)
    }
}

extension Analysis {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isRecent: Bool {
        Date().timeIntervalSince(date) < 86400 // Within last 24 hours
    }
}

extension Analysis {
    static let mock = Analysis(
        timestamp: Int64(Date().timeIntervalSince1970),
        content: "Your workout performance has been strong this week. You've shown consistent progress on compound movements, with your bench press showing a 5% increase in volume. Consider adding more accessory work for your shoulders to support continued growth. Your squat depth has improved significantly - keep focusing on that mobility work."
    )
}