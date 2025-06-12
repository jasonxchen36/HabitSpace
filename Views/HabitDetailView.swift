import SwiftUI
import CoreData

struct HabitDetailView: View {
    @StateObject private var viewModel: HabitDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingAddNote = false
    @State private var newNote = ""
    
    init(habit: Habit) {
        _viewModel = StateObject(wrappedValue: HabitDetailViewModel(habit: habit))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Stats Cards
                statsSection
                
                // Progress Section
                progressSection
                
                // Complete Button
                completeButton
                
                // Completion History
                completionHistorySection
                
                // Notes Section
                notesSection
                
                // AR Anchor Section (if supported)
                if ARWorldTrackingConfiguration.isSupported {
                    arAnchorSection
                }
                
                Spacer()
                
                // Delete Button
                deleteButton
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEditView = true }
            }
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteHabit()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditView) {
            NavigationView {
                AddHabitView(habitToEdit: viewModel.habit)
                    .navigationTitle("Edit Habit")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showingAddNote) {
            noteEditorView
        }
        .task {
            // Load any initial data
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(viewModel.habit.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: viewModel.habit.wrappedIconName)
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.habit.color)
            }
            
            Text(viewModel.habit.wrappedName)
                .font(.title2)
                .fontWeight(.bold)
            
            if !viewModel.habit.wrappedNotes.isEmpty {
                Text(viewModel.habit.wrappedNotes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Current Streak",
                value: "\(viewModel.habit.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "Best Streak",
                value: "\(viewModel.habit.bestStreak)",
                icon: "star.fill",
                color: .yellow
            )
            
            StatCard(
                title: "Total",
                value: "\(viewModel.habit.completions?.count ?? 0)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(viewModel.completionRate * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: viewModel.completionRate, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: viewModel.habit.color))
            
            if viewModel.habit.wrappedTargetCount > 1 {
                Text("\(viewModel.habit.completions?.count ?? 0) of \(viewModel.habit.wrappedTargetCount) completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var completeButton: some View {
        Button(action: { Task { await viewModel.toggleCompletion() } }) {
            HStack {
                Image(systemName: viewModel.isCompletedToday ? "checkmark.circle.fill" : "plus.circle.fill")
                Text(viewModel.isCompletedToday ? "Completed Today" : "Mark as Complete")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isCompletedToday ? Color.green.opacity(0.2) : viewModel.habit.color.opacity(0.2))
            .foregroundColor(viewModel.isCompletedToday ? .green : viewModel.habit.color)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Completion History
    
    private var completionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Completion History")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.completionDates.isEmpty {
                    Button("See All") {
                        // TODO: Show full history view
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if viewModel.completionDates.isEmpty {
                emptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No Completions Yet",
                    message: "Complete this habit to see your history here"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.completionDates.prefix(7), id: \.self) { date in
                            VStack(spacing: 8) {
                                Text(dayOfWeekFormatter.string(from: date))
                                    .font(.caption2)
                                
                                ZStack {
                                    Circle()
                                        .fill(viewModel.habit.color.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text(dayOfMonthFormatter.string(from: date))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if let notes = viewModel.habit.completionsArray.compactMap({ $0.notes }).filter({ !$0.isEmpty }),
               !notes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(notes.prefix(3), id: \.self) { note in
                        NoteRow(note: note, color: viewModel.habit.color)
                    }
                }
            } else {
                emptyStateView(
                    icon: "note.text",
                    title: "No Notes Yet",
                    message: "Add notes when you complete this habit"
                )
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - AR Anchor Section
    
    private var arAnchorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AR Anchor")
                .font(.headline)
            
            NavigationLink(destination: ARHabitView(selectedHabit: viewModel.habit)) {
                HStack {
                    Image(systemName: "arkit")
                    Text("Place in AR")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            Text("Delete Habit")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.bottom, 30)
        }
    }
    
    // MARK: - Helper Views
    
    private var noteEditorView: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextEditor(text: $newNote)
                    .frame(minHeight: 150)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        newNote.isEmpty ?
                        Text("Add your notes here...")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        : nil
                    )
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.completeHabit(notes: newNote)
                        showingAddNote = false
                        newNote = ""
                    }
                }) {
                    Text("Save & Complete")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.habit.color)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddNote = false
                        newNote = ""
                    }
                }
            }
        }
    }
}

// MARK: - Previews
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
        
        // Add some completions
        for day in 0..<5 {
            let completion = HabitCompletion(context: context)
            completion.id = UUID()
            completion.timestamp = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
            completion.habit = habit
        }
        
        return NavigationView {
            HabitDetailView(habit: habit)
                .environment(\.managedObjectContext, context)
                .environmentObject(HabitManager.shared)
        }
    }
}
