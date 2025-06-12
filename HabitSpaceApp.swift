import SwiftUI
import CoreData

@main
struct HabitSpaceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    
    // Initialize managers
    private let coreDataManager = CoreDataManager.shared
    private let habitManager = HabitManager.shared
    private let notificationManager = NotificationManager.shared
    private let arManager = ARManager.shared
    
    // App state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environment(\.managedObjectContext, coreDataManager.context)
                        .environmentObject(appState)
                        .onAppear {
                            // Request notification authorization when app launches
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                            
                            // Load saved AR anchors
                            arManager.loadSavedAnchors()
                            
                            // Update streaks when app becomes active
                            habitManager.updateStreaks()
                        }
                } else {
                    OnboardingView()
                        .environment(\.managedObjectContext, coreDataManager.context)
                }
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    // App became active, update streaks and notifications
                    habitManager.updateStreaks()
                    Task {
                        await notificationManager.refreshPendingNotifications()
                    }
                case .inactive, .background:
                    // App going to background, save context
                    coreDataManager.saveContext()
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure app appearance
        configureAppearance()
        
        // Setup notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        return true
    }
    
    private func configureAppearance() {
        // Customize navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        }
        
        // Customize tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var selectedHabit: Habit?
    @Published var showARView = false
    
    enum Tab: Hashable {
        case home, ar, add, stats, profile
    }
}

// MARK: - Preview
struct HabitSpaceApp_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.preview.container.viewContext
        
        // Add sample data for preview
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Sample Habit"
        habit.iconName = "star.fill"
        habit.colorHex = "FF2D55"
        habit.targetCount = 1
        habit.currentStreak = 3
        habit.bestStreak = 5
        habit.createdAt = Date()
        
        return HabitSpaceApp()
            .environment(\.managedObjectContext, context)
    }
}
