import Foundation

struct WorkoutSet: Identifiable, Codable {
    let id = UUID()
    let workoutId: String
    let timestamp: Int64
    let exercise: String
    let reps: String
    let sets: Int32
    let weight: Float
    let weightModulation: String?
    
    enum CodingKeys: String, CodingKey {
        case workoutId = "workoutId"
        case timestamp
        case exercise
        case reps
        case sets
        case weight
        case weightModulation = "weight_modulation"
    }
    
    init(workoutId: String, timestamp: Int64, exercise: String, reps: String, sets: Int32, weight: Float, weightModulation: String? = nil) {
        self.workoutId = workoutId
        self.timestamp = timestamp
        self.exercise = exercise
        self.reps = reps
        self.sets = sets
        self.weight = weight
        self.weightModulation = weightModulation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workoutId = try container.decode(String.self, forKey: .workoutId)
        
        // Handle timestamp as string from backend
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        timestamp = Int64(timestampString) ?? 0
        
        exercise = try container.decode(String.self, forKey: .exercise)
        reps = try container.decode(String.self, forKey: .reps)
        
        // Handle sets as string from backend
        let setsString = try container.decode(String.self, forKey: .sets)
        sets = Int32(setsString) ?? 1
        
        // Handle weight as string from backend
        let weightString = try container.decode(String.self, forKey: .weight)
        weight = Float(weightString) ?? 0.0
        
        weightModulation = try container.decodeIfPresent(String.self, forKey: .weightModulation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workoutId, forKey: .workoutId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(exercise, forKey: .exercise)
        try container.encode(reps, forKey: .reps)
        try container.encode(sets, forKey: .sets)
        try container.encode(weight, forKey: .weight)
        try container.encodeIfPresent(weightModulation, forKey: .weightModulation)
    }
}

extension WorkoutSet {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isFromCuttingPhase: Bool {
        weightModulation?.lowercased() == "cutting"
    }
    
    var estimated1RM: Float {
        guard let repsInt = Int(reps), repsInt > 0 else { return weight }
        return weight / (1.0278 - 0.0278 * Float(repsInt))
    }
}

extension WorkoutSet {
    static let mock = WorkoutSet(
        workoutId: "workout-123",
        timestamp: Int64(Date().timeIntervalSince1970),
        exercise: "Bench Press",
        reps: "8",
        sets: 1,
        weight: 185.0,
        weightModulation: "Bulking"
    )
    
    static let mockArray = [
        WorkoutSet(workoutId: "workout-123", timestamp: Int64(Date().timeIntervalSince1970), exercise: "Bench Press", reps: "8", sets: 1, weight: 185.0, weightModulation: "Bulking"),
        WorkoutSet(workoutId: "workout-124", timestamp: Int64(Date().timeIntervalSince1970 - 3600), exercise: "Squat", reps: "10", sets: 1, weight: 225.0, weightModulation: "Bulking"),
        WorkoutSet(workoutId: "workout-125", timestamp: Int64(Date().timeIntervalSince1970 - 7200), exercise: "Deadlift", reps: "5", sets: 1, weight: 275.0, weightModulation: "Cutting")
    ]
}