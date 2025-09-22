import Foundation

struct InjuryEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Int64
    let location: String
    let details: String?
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case timestamp
        case location
        case details
        case active
    }

    init(timestamp: Int64, location: String, details: String?, active: Bool) {
        self.timestamp = timestamp
        self.location = location
        self.details = details
        self.active = active
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Backend returns map[string]string, convert fields as needed
        let tsString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = Int64(tsString) ?? 0

        self.location = try container.decode(String.self, forKey: .location)

        // Details may be missing
        if let detailsString = try? container.decode(String.self, forKey: .details) {
            self.details = detailsString
        } else {
            self.details = nil
        }

        // Active may come as "true"/"false" string
        if let activeString = try? container.decode(String.self, forKey: .active) {
            self.active = (activeString as NSString).boolValue
        } else if let activeBool = try? container.decode(Bool.self, forKey: .active) {
            self.active = activeBool
        } else {
            self.active = true
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(details, forKey: .details)
        try container.encode(active, forKey: .active)
    }
}

extension InjuryEntry {
    var date: Date { Date(timeIntervalSince1970: TimeInterval(timestamp)) }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

