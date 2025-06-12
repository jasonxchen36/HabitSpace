import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject private var habitManager: HabitManager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var showingAddHabit = false
    @State private var showingProfile = false
    @State private var selectedHabit: Habit?
    @State private var showingHabitDetail = false
    @State private var showingOnboarding = false
    @State private var searchText = ""
    
    // Filter habits based on search text
    private var filteredHabits: [Habit] {
        if searchText.isEmpty {
            return habitManager.habits
        } else {
            return habitManager.habits.filter {
                $0.wrappedName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Group habits by completion status
    private var habitsByCompletion: [Bool: [Habit]] {
        Dictionary(grouping: filteredHabits, by: \.isCompletedToday)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting and date
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getGreeting())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Stats summary
                    StatsSummaryView()
                        .padding(.horizontal)
                    
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // Habits list
                    if filteredHabits.isEmpty {
                        emptyStateView
                    } else {
                        // Incomplete habits
                        if let incompleteHabits = habitsByCompletion[false], !incompleteHabits.isEmpty {
                            Section(header: sectionHeader("To Do Today")) {
                                ForEach(incompleteHabits) { habit in
                                    HabitRow(habit: habit) {
                                        selectedHabit = habit
                                        showingHabitDetail = true
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // Completed habits
                        if let completedHabits = habitsByCompletion[true], !completedHabits.isEmpty {
                            Section(header: sectionHeader("Completed")) {
                                ForEach(completedHabits) { habit in
                                    HabitRow(habit: habit) {
                                        selectedHabit = habit
                                        showingHabitDetail = true
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    .opacity(0.6)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 80) // Space for FAB
                }
                .padding(.bottom)
            }
            .refreshable {
                // Pull to refresh
                habitManager.fetchHabits()
            }
            
            // Floating Action Button
            Button(action: { showingAddHabit = true }) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .padding()
            .accessibilityLabel("Add new habit")
        }
        .sheet(isPresented: $showingAddHabit) {
            NavigationView {
                AddHabitView()
                    .navigationTitle("New Habit")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddHabit = false
                            }
                        }
                    }
            }
        }
        .sheet(item: $selectedHabit) { habit in
            NavigationView {
                HabitDetailView(habit: habit)
                    .navigationTitle(habit.wrappedName)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            // Refresh data when view appears
            habitManager.fetchHabits()
            
            // Check if we should show onboarding
            if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                showingOnboarding = true
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
    
    // MARK: - Helper Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.3))
                .padding()
            
            Text("No Habits Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first habit and start building positive routines.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddHabit = true }) {
                Label("Add Your First Habit", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(.top, 80)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading)
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
}

// MARK: - Habit Row
struct HabitRow: View {
    @ObservedObject var habit: Habit
    var action: () -> Void
    
    @State private var isCompleted: Bool
    
    init(habit: Habit, action: @escaping () -> Void) {
        self.habit = habit
        self.action = action
        _isCompleted = State(initialValue: habit.isCompletedToday)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Completion indicator
                ZStack {
                    Circle()
                        .stroke(habit.color, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(habit.color)
                    }
                }
                .onTapGesture {
                    // Toggle completion
                    withAnimation {
                        isCompleted.toggle()
                        if isCompleted {
                            HabitManager.shared.completeHabit(habit)
                        } else {
                            // TODO: Handle uncompleting a habit
                        }
                    }
                }
                
                // Habit info
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.wrappedName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        // Streak
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(habit.currentStreak)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Next reminder
                        if let reminderTime = habit.reminderTime, habit.reminderEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.blue)
                                Text(reminderTime, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Habit icon
                Image(systemName: habit.wrappedIconName)
                    .font(.title2)
                    .foregroundColor(habit.color)
                    .frame(width: 44, height: 44)
                    .background(habit.color.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stats Summary View
struct StatsSummaryView: View {
    @EnvironmentObject private var habitManager: HabitManager
    
    private var totalHabits: Int {
        habitManager.habits.count
    }
    
    private var completedToday: Int {
        habitManager.habits.filter { $0.isCompletedToday }.count
    }
    
    private var currentStreak: Int {
        habitManager.habits.map { Int($0.currentStreak) }.max() ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Total Habits
            StatCard(
                title: "Total Habits",
                value: "\(totalHabits)",
                icon: "checklist",
                color: .blue
            )
            
            // Completed Today
            StatCard(
                title: "Today",
                value: "\(completedToday)/\(totalHabits)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            // Current Streak
            StatCard(
                title: "Day Streak",
                value: "\(currentStreak)",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
}

// MARK: - Stat Card View
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search habits...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.preview.container.viewContext
        
        // Add sample data
        let habit1 = Habit(context: context)
        habit1.id = UUID()
        habit1.name = "Drink Water"
        habit1.iconName = "drop.fill"
        habit1.colorHex = "007AFF"
        habit1.targetCount = 8
        habit1.currentStreak = 5
        habit1.bestStreak = 7
        habit1.createdAt = Date()
        
        let habit2 = Habit(context: context)
        habit2.id = UUID()
        habit2.name = "Exercise"
        habit2.iconName = "figure.walk"
        habit2.colorHex = "34C759"
        habit2.targetCount = 1
        habit2.currentStreak = 2
        habit2.bestStreak = 10
        habit2.createdAt = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        
        let habit3 = Habit(context: context)
        habit3.id = UUID()
        habit3.name = "Meditate"
        habit3.iconName = "leaf.fill"
        habit3.colorHex = "AF52DE"
        habit3.targetCount = 1
        habit3.currentStreak = 0
        habit3.bestStreak = 0
        habit3.createdAt = Date()
        
        // Create completion for habit1
        let completion = HabitCompletion(context: context)
        completion.id = UUID()
        completion.timestamp = Date()
        completion.habit = habit1
        
        return HomeView()
            .environment(\.managedObjectContext, context)
            .environmentObject(HabitManager.preview)
            .environmentObject(AppState())
    }
}
