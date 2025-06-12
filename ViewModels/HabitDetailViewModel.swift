import Foundation
import CoreData

@MainActor
class HabitDetailViewModel: ObservableObject {
    @Published private(set) var habit: Habit
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private let habitManager: HabitManager
    private let notificationManager: NotificationManager
    
    init(habit: Habit, habitManager: HabitManager = .shared, notificationManager: NotificationManager = .shared) {
        self.habit = habit
        self.habitManager = habitManager
        self.notificationManager = notificationManager
    }
    
    var completionRate: Double {
        habit.completionRate
    }
    
    var isCompletedToday: Bool {
        habit.isCompletedToday
    }
    
    var completionDates: [Date] {
        habit.completionDates
    }
    
    func toggleCompletion() async {
        do {
            if isCompletedToday {
                // Undo today's completion
                if let completion = habit.completionsArray.first(where: { completion in
                    Calendar.current.isDateInToday(completion.wrappedTimestamp)
                }) {
                    await deleteCompletion(completion)
                }
            } else {
                // Complete for today
                await completeHabit()
            }
        } catch {
            self.error = error
        }
    }
    
    private func completeHabit(notes: String? = nil) async {
        do {
            try await Task {
                habitManager.completeHabit(habit, notes: notes)
            }.value
            objectWillChange.send()
        } catch {
            self.error = error
        }
    }
    
    private func deleteCompletion(_ completion: HabitCompletion) async {
        do {
            try await Task {
                habit.managedObjectContext?.delete(completion)
                try habit.managedObjectContext?.save()
            }.value
            objectWillChange.send()
        } catch {
            self.error = error
        }
    }
    
    func deleteHabit() async throws {
        try await Task {
            habitManager.deleteHabit(habit)
        }.value
    }
    
    func updateReminder(enabled: Bool, time: Date? = nil) async {
        do {
            try await Task {
                habit.reminderEnabled = enabled
                if let time = time {
                    habit.reminderTime = time
                }
                
                if enabled {
                    try await notificationManager.scheduleNotification(for: habit)
                } else {
                    notificationManager.removePendingNotifications(for: habit)
                }
                
                try habit.managedObjectContext?.save()
            }.value
            objectWillChange.send()
        } catch {
            self.error = error
        }
    }
}
