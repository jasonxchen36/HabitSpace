import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var habitManager: HabitManager
    @EnvironmentObject private var arManager: ARManager
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var showAddHabit = false
    @State private var selectedTab: AppState.Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                HomeView()
                    .navigationTitle("Habits")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppState.Tab.home)
            
            // AR View Tab
            NavigationView {
                ARHabitView()
                    .navigationTitle("AR View")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("AR", systemImage: "arkit")
            }
            .tag(AppState.Tab.ar)
            
            // Add Habit Button (Center Tab)
            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                }
                .tag(AppState.Tab.add)
                .onAppear {
                    showAddHabit = true
                }
            
            // Stats Tab
            NavigationView {
                StatsView()
                    .navigationTitle("Stats")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(AppState.Tab.stats)
            
            // Profile Tab
            NavigationView {
                ProfileView()
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(AppState.Tab.profile)
        }
        .accentColor(.blue)
        .onAppear {
            // Set up tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            // Request notification authorization if needed
            Task {
                await notificationManager.requestAuthorization()
            }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == .add {
                showAddHabit = true
                // Reset to home tab after showing add habit
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = .home
                }
            }
        }
        .sheet(isPresented: $showAddHabit) {
            NavigationView {
                AddHabitView()
                    .navigationTitle("New Habit")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddHabit = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.preview.container.viewContext
        
        return MainTabView()
            .environment(\.managedObjectContext, context)
            .environmentObject(AppState())
            .environmentObject(HabitManager.preview)
            .environmentObject(ARManager.preview)
            .environmentObject(NotificationManager.preview)
    }
}
