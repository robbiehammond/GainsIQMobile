import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name
    }
    
    init(name: String) {
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}

extension Exercise {
    static let mock = Exercise(name: "Bench Press")
    static let mockArray = [
        Exercise(name: "Bench Press"),
        Exercise(name: "Squat"),
        Exercise(name: "Deadlift"),
        Exercise(name: "Pull-ups")
    ]
}