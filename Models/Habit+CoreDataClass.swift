import Foundation
import CoreData

@objc(Habit)
public class Habit: NSManagedObject, Identifiable {
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedName: String { name ?? "" }
    public var wrappedIconName: String { iconName ?? "star.fill" }
    public var wrappedColorHex: String { colorHex ?? "000000" }
    public var wrappedCreatedAt: Date { createdAt ?? Date() }
    public var wrappedLastUpdated: Date { lastUpdated ?? Date() }
    
    public var uiColor: UIColor {
        return UIColor(hex: wrappedColorHex) ?? .systemBlue
    }
    
    public var color: Color {
        return Color(uiColor)
    }
    
    public var progress: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentStreak) / Double(targetCount)
    }
    
    public var isCompletedToday: Bool {
        guard let completions = completions as? Set<HabitCompletion> else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        return completions.contains { completion in
            guard let date = completion.timestamp else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }
    }
}

// MARK: - Preview Helpers
extension Habit {
    static var preview: Habit {
        let habit = Habit(context: CoreDataManager.preview.container.viewContext)
        habit.id = UUID()
        habit.name = "Drink Water"
        habit.iconName = "drop.fill"
        habit.colorHex = "007AFF"
        habit.targetCount = 8
        habit.currentStreak = 5
        habit.bestStreak = 7
        habit.createdAt = Date()
        habit.lastUpdated = Date()
        return habit
    }
}
