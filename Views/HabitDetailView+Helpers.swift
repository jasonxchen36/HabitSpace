import SwiftUI

// MARK: - Helper Extensions

extension Habit {
    var completionRate: Double {
        guard targetCount > 0 else { return 0 }
        let completions = (completions?.count ?? 0)
        return min(Double(completions) / Double(targetCount), 1.0)
    }
    
    var isCompletedToday: Bool {
        guard let completions = completions as? Set<HabitCompletion> else { return false }
        return completions.contains { completion in
            Calendar.current.isDateInToday(completion.wrappedTimestamp)
        }
    }
    
    var completionDates: [Date] {
        guard let completions = completions as? Set<HabitCompletion> else { return [] }
        return completions.map { $0.wrappedTimestamp }.sorted(by: >)
    }
    
    var completionsArray: [HabitCompletion] {
        guard let completions = completions as? Set<HabitCompletion> else { return [] }
        return Array(completions).sorted { $0.wrappedTimestamp > $1.wrappedTimestamp }
    }
}

// MARK: - Formatters

private let dayOfWeekFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter
}()

private let dayOfMonthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
}()

// MARK: - Helper Views

struct NoteRow: View {
    let note: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            Text(note)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - View Extension

extension View {
    func emptyStateView(icon: String, title: String, message: String) -> some View {
        self.overlay(
            EmptyStateView(icon: icon, title: title, message: message)
        )
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct HabitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.preview.container.viewContext
        let habit = Habit(context: context)
        habit.id = UUID()
        habit.name = "Drink Water"
        habit.iconName = "drop.fill"
        habit.colorHex = "007AFF"
        habit.targetCount = 8
        habit.notes = "Stay hydrated throughout the day"
        
        // Add some completions with notes
        for day in 0..<5 {
            let completion = HabitCompletion(context: context)
            completion.id = UUID()
            completion.timestamp = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
            completion.notes = day == 0 ? "Drank 8 glasses today!" : "Completed"
            completion.habit = habit
        }
        
        return NavigationView {
            HabitDetailView(habit: habit)
                .environment(\.managedObjectContext, context)
                .environmentObject(HabitManager.shared)
                .environmentObject(NotificationManager.shared)
        }
    }
}

struct NoteRow_Previews: PreviewProvider {
    static var previews: some View {
        NoteRow(
            note: "This is a sample note about completing the habit.",
            color: .blue
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            icon: "note.text",
            title: "No Notes Yet",
            message: "Add notes when you complete this habit"
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
