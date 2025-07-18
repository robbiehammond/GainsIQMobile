import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func endOfDay() -> Date {
        let startOfDay = self.startOfDay()
        return Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }
    
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfWeek() -> Date {
        let startOfWeek = self.startOfWeek()
        return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)?.addingTimeInterval(-1) ?? self
    }
    
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfMonth() -> Date {
        let startOfMonth = self.startOfMonth()
        return Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) ?? self
    }
    
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }
    
    func timeAgo() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }
    
    var unixTimestamp: Int64 {
        return Int64(self.timeIntervalSince1970)
    }
}

// MARK: - String Extensions

extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

// MARK: - Array Extensions

extension Array where Element == WorkoutSet {
    func groupedByDate() -> [Date: [WorkoutSet]] {
        return Dictionary(grouping: self) { workoutSet in
            Calendar.current.startOfDay(for: workoutSet.date)
        }
    }
    
    func groupedByExercise() -> [String: [WorkoutSet]] {
        return Dictionary(grouping: self) { $0.exercise }
    }
    
    func sortedByDate(ascending: Bool = true) -> [WorkoutSet] {
        return self.sorted { set1, set2 in
            if ascending {
                return set1.timestamp < set2.timestamp
            } else {
                return set1.timestamp > set2.timestamp
            }
        }
    }
    
    func totalVolume() -> Float {
        return self.reduce(0) { total, set in
            if let reps = Int(set.reps) {
                return total + (set.weight * Float(reps))
            }
            return total
        }
    }
    
    func averageWeight() -> Float {
        guard !self.isEmpty else { return 0 }
        let totalWeight = self.reduce(0) { $0 + $1.weight }
        return totalWeight / Float(self.count)
    }
    
    func averageReps() -> Float {
        guard !self.isEmpty else { return 0 }
        let totalReps = self.reduce(0.0) { total, set in
            if let reps = Int(set.reps) {
                return total + Double(Float(reps))
            }
            return total
        }
        return Float(totalReps) / Float(self.count)
    }
    
    func maxWeight() -> Float {
        return self.max { $0.weight < $1.weight }?.weight ?? 0
    }
}

extension Array where Element == WeightEntry {
    func sortedByDate(ascending: Bool = true) -> [WeightEntry] {
        return self.sorted { entry1, entry2 in
            if ascending {
                return entry1.timestamp < entry2.timestamp
            } else {
                return entry1.timestamp > entry2.timestamp
            }
        }
    }
    
    func averageWeight() -> Float {
        guard !self.isEmpty else { return 0 }
        let totalWeight = self.reduce(0) { $0 + $1.weight }
        return totalWeight / Float(self.count)
    }
    
    func weightChange() -> Float {
        guard self.count >= 2 else { return 0 }
        let sorted = self.sortedByDate()
        return sorted.last!.weight - sorted.first!.weight
    }
}

// MARK: - View Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func successHaptic() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
    }
    
    func errorHaptic() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.error)
    }
}

// MARK: - Color Extensions

extension Color {
    static let gainsiqPrimary = Color("GainsIQPrimary")
    static let gainsiqSecondary = Color("GainsIQSecondary")
    static let gainsiqBackground = Color("GainsIQBackground")
    static let gainsiqCardBackground = Color("GainsIQCardBackground")
    static let gainsiqText = Color("GainsIQText")
    static let gainsiqTextSecondary = Color("GainsIQTextSecondary")
    
    // Fallback colors if custom colors aren't defined
    static let primaryFallback = Color.blue
    static let secondaryFallback = Color.gray
    static let backgroundFallback = Color(UIColor.systemBackground)
    static let cardBackgroundFallback = Color(UIColor.secondarySystemBackground)
    static let textFallback = Color(UIColor.label)
    static let textSecondaryFallback = Color(UIColor.secondaryLabel)
}

// MARK: - Number Extensions

extension Float {
    func rounded(toPlaces places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
    
    func formattedWeight(unit: WeightUnit) -> String {
        return String(format: "%.1f %@", self, unit.abbreviation)
    }
}

extension Int {
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Binding Extensions

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// MARK: - UIDevice Extensions

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0
        }
        return false
    }
    
    var isIPhone: Bool {
        return userInterfaceIdiom == .phone
    }
    
    var isIPad: Bool {
        return userInterfaceIdiom == .pad
    }
}

// MARK: - Task Extensions

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
