import Foundation
import CoreData
import Combine

class HabitManager: ObservableObject {
    static let shared = HabitManager()
    
    // Published properties
    @Published var habits: [Habit] = []
    @Published var selectedHabit: Habit?
    @Published var isLoading = false
    @Published var error: Error?
    
    // Private properties
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        fetchHabits()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update local habits when Core Data changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchHabits()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    func createHabit(name: String, iconName: String, colorHex: String, targetCount: Int16 = 1) -> Habit {
        let habit = coreDataManager.createHabit(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            targetCount: targetCount
        )
        fetchHabits()
        return habit
    }
    
    func fetchHabits() {
        isLoading = true
        
        do {
            habits = try coreDataManager.fetchHabits()
            error = nil
        } catch {
            self.error = error
            print("Error fetching habits: \(error)")
        }
        
        isLoading = false
    }
    
    func updateHabit(_ habit: Habit) {
        habit.lastUpdated = Date()
        coreDataManager.saveContext()
    }
    
    func deleteHabit(_ habit: Habit) {
        // Remove any associated notifications
        NotificationManager.shared.removePendingNotifications(for: habit)
        
        // Delete from Core Data
        coreDataManager.context.delete(habit)
        coreDataManager.saveContext()
        
        // Update local array
        if let index = habits.firstIndex(of: habit) {
            habits.remove(at: index)
        }
    }
    
    // MARK: - Habit Completion
    func completeHabit(_ habit: Habit, notes: String? = nil) {
        coreDataManager.completeHabit(habit, notes: notes)
        
        // Update streak information
        habit.currentStreak += 1
        if habit.currentStreak > habit.bestStreak {
            habit.bestStreak = habit.currentStreak
        }
        
        // Save changes
        updateHabit(habit)
    }
    
    // MARK: - Streak Management
    func updateStreaks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for habit in habits {
            guard let lastCompletion = (habit.completions as? Set<HabitCompletion>)?.max(by: { $0.wrappedTimestamp < $1.wrappedTimestamp })?.timestamp else {
                // No completions, reset streak
                if habit.currentStreak > 0 {
                    habit.currentStreak = 0
                    updateHabit(habit)
                }
                continue
            }
            
            let lastCompletionDay = calendar.startOfDay(for: lastCompletion)
            let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastCompletionDay, to: today).day ?? 0
            
            if daysSinceLastCompletion > 1 {
                // Streak broken
                habit.currentStreak = 0
                updateHabit(habit)
            } else if daysSinceLastCompletion == 1 {
                // Check if habit was completed today
                let completedToday = (habit.completions as? Set<HabitCompletion>)?.contains { completion in
                    calendar.isDate(completion.wrappedTimestamp, inSameDayAs: today)
                } ?? false
                
                if !completedToday {
                    // Streak continues
                    habit.currentStreak += 1
                    if habit.currentStreak > habit.bestStreak {
                        habit.bestStreak = habit.currentStreak
                    }
                    updateHabit(habit)
                }
            }
        }
    }
    
    // MARK: - Stats
    func statsForLast(days: Int) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        var stats: [Date: Int] = [:]
        
        // Initialize dictionary with all dates in range
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                stats[date] = 0
            }
        }
        
        // Count completions for each date
        let allCompletions = habits.flatMap { ($0.completions as? Set<HabitCompletion>)?.map { $0.wrappedTimestamp } ?? [] }
        
        for completion in allCompletions {
            let completionDate = calendar.startOfDay(for: completion)
            if completionDate >= startDate && completionDate <= today {
                stats[completionDate, default: 0] += 1
            }
        }
        
        return stats
    }
    
    // MARK: - Preview Helper
    static var preview: HabitManager {
        let manager = HabitManager()
        // Add some sample habits for preview
        let habit1 = Habit(context: CoreDataManager.preview.container.viewContext)
        habit1.id = UUID()
        habit1.name = "Drink Water"
        habit1.iconName = "drop.fill"
        habit1.colorHex = "007AFF"
        habit1.targetCount = 8
        habit1.currentStreak = 5
        habit1.bestStreak = 7
        habit1.createdAt = Date()
        
        let habit2 = Habit(context: CoreDataManager.preview.container.viewContext)
        habit2.id = UUID()
        habit2.name = "Exercise"
        habit2.iconName = "figure.walk"
        habit2.colorHex = "34C759"
        habit2.targetCount = 1
        habit2.currentStreak = 2
        habit2.bestStreak = 10
        habit2.createdAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        
        manager.habits = [habit1, habit2]
        return manager
    }
}
