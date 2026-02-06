import Foundation
import BackgroundTasks
import UIKit

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    // Task identifiers - must match Info.plist
    private let refreshTaskIdentifier = "com.habitspace.refresh"
    private let streakUpdateTaskIdentifier = "com.habitspace.streakupdate"
    
    private let habitManager = HabitManager.shared
    private let notificationManager = NotificationManager.shared
    
    private init() {}
    
    // MARK: - Registration
    func registerBackgroundTasks() {
        // Register app refresh task for notification updates
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register processing task for streak updates
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: streakUpdateTaskIdentifier,
            using: nil
        ) { task in
            self.handleStreakUpdate(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Scheduling
    func scheduleBackgroundTasks() {
        scheduleAppRefresh()
        scheduleStreakUpdate()
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background app refresh scheduled")
        } catch {
            print("❌ Could not schedule app refresh: \(error)")
        }
    }
    
    private func scheduleStreakUpdate() {
        let request = BGProcessingTaskRequest(identifier: streakUpdateTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        // Schedule for next midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        request.earliestBeginDate = nextMidnight
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Streak update scheduled for \(nextMidnight)")
        } catch {
            print("❌ Could not schedule streak update: \(error)")
        }
    }
    
    // MARK: - Task Handlers
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleAppRefresh()
        
        // Create operation for refreshing notifications
        let operation = BlockOperation {
            Task {
                // Refresh all habit notifications
                await self.refreshAllNotifications()
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            operation.cancel()
        }
        
        // Mark task complete when operation finishes
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        // Execute operation
        OperationQueue().addOperation(operation)
    }
    
    private func handleStreakUpdate(task: BGProcessingTask) {
        // Schedule next streak update
        scheduleStreakUpdate()
        
        // Create operation for updating streaks
        let operation = BlockOperation {
            // Update all habit streaks
            self.habitManager.updateStreaks()
        }
        
        // Set expiration handler
        task.expirationHandler = {
            operation.cancel()
        }
        
        // Mark task complete when operation finishes
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        // Execute operation
        OperationQueue().addOperation(operation)
    }
    
    // MARK: - Notification Refresh
    private func refreshAllNotifications() async {
        let habits = habitManager.habits
        
        for habit in habits {
            do {
                // Remove existing notifications
                notificationManager.removePendingNotifications(for: habit)
                
                // Reschedule if enabled
                if habit.reminderEnabled || habit.locationReminderEnabled {
                    try await notificationManager.scheduleNotification(for: habit)
                }
            } catch {
                print("Error refreshing notification for habit \(habit.wrappedName): \(error)")
            }
        }
        
        print("✅ Refreshed notifications for \(habits.count) habits")
    }
}
