import Foundation

struct InjuryEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Int64
    let location: String
    let details: String?
    let active: Bool
    let activePeriods: [InjuryActivePeriod]?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case location
        case details
        case active
        case activePeriods
    }

    init(timestamp: Int64, location: String, details: String?, active: Bool, activePeriods: [InjuryActivePeriod]? = nil) {
        self.timestamp = timestamp
        self.location = location
        self.details = details
        self.active = active
        self.activePeriods = activePeriods
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

        // Active periods may be absent or come in standard typed form
        self.activePeriods = try? container.decodeIfPresent([InjuryActivePeriod].self, forKey: .activePeriods)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(details, forKey: .details)
        try container.encode(active, forKey: .active)
        try container.encodeIfPresent(activePeriods, forKey: .activePeriods)
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

// MARK: - Active Period Model

struct InjuryActivePeriod: Codable {
    let start: Int64
    let end: Int64?

    enum CodingKeys: String, CodingKey {
        case start
        case end
    }

    init(start: Int64, end: Int64?) {
        self.start = start
        self.end = end
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle start as either number or string
        if let startInt = try? container.decode(Int64.self, forKey: .start) {
            self.start = startInt
        } else if let startString = try? container.decode(String.self, forKey: .start),
                  let startInt = Int64(startString) {
            self.start = startInt
        } else {
            self.start = 0
        }

        // Handle end as either number, string, or omitted
        if let endInt = try? container.decode(Int64.self, forKey: .end) {
            self.end = endInt
        } else if let endString = try? container.decode(String.self, forKey: .end),
                  let endInt = Int64(endString) {
            self.end = endInt
        } else if (try? container.decodeNil(forKey: .end)) == true {
            self.end = nil
        } else {
            self.end = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encodeIfPresent(end, forKey: .end)
    }
}

extension InjuryActivePeriod {
    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(start)) }
    var endDate: Date? { end.map { Date(timeIntervalSince1970: TimeInterval($0)) } }

    var formattedRange: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        let startStr = df.string(from: startDate)
        if let ed = endDate {
            let endStr = df.string(from: ed)
            return "\(startStr) – \(endStr)"
        } else {
            return "\(startStr) – Present"
        }
    }
}
