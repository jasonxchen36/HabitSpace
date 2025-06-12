import UserNotifications
import CoreLocation

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let locationManager = CLLocationManager()
    
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleNotification(for habit: Habit) async throws {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for \(habit.wrappedName)"
        content.body = "Don't forget to complete your habit!"
        content.sound = .default
        content.userInfo = ["habitId": habit.wrappedId.uuidString]
        
        // Schedule for a specific time if set
        if let reminderTime = habit.reminderTime, habit.reminderEnabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "\(habit.wrappedId)_time",
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
        }
        
        // Schedule for location if enabled
        if habit.locationReminderEnabled {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(
                    latitude: habit.locationLatitude,
                    longitude: habit.locationLongitude
                ),
                radius: habit.locationRadius > 0 ? habit.locationRadius : 100,
                identifier: "\(habit.wrappedId)_location"
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "\(habit.wrappedId)_location",
                content: content,
                trigger: trigger
            )
            
            try await notificationCenter.add(request)
        }
    }
    
    // MARK: - Notification Management
    func removePendingNotifications(for habit: Habit) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["\(habit.wrappedId)_time", "\(habit.wrappedId)_location"]
        )
    }
    
    func updateNotification(for habit: Habit) async throws {
        await removePendingNotifications(for: habit)
        try await scheduleNotification(for: habit)
    }
    
    // MARK: - Fetch Pending Notifications
    func refreshPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        await MainActor.run {
            self.pendingNotifications = requests
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        if let habitIdString = userInfo["habitId"] as? String,
           let habitId = UUID(uuidString: habitIdString) {
            // Navigate to the specific habit
            NotificationCenter.default.post(
                name: .didTapHabitNotification,
                object: nil,
                userInfo: ["habitId": habitId]
            )
        }
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didTapHabitNotification = Notification.Name("didTapHabitNotification")
}

// MARK: - Preview Helper
extension NotificationManager {
    static var preview: NotificationManager {
        let manager = NotificationManager()
        manager.isAuthorized = true
        return manager
    }
}
