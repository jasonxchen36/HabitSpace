import SwiftUI
import ARKit
import RealityKit
import CoreData

struct ARHabitView: View {
    @EnvironmentObject private var arManager: ARManager
    @EnvironmentObject private var habitManager: HabitManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showHabitSelection = false
    @State private var showTutorial = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPlacingAnchor = false
    @State private var selectedHabit: Habit?
    @State private var showDeleteAlert = false
    @State private var anchorToDelete: ARAnchor?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // AR View
            ARViewContainer()
                .environmentObject(arManager)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    _ = arManager.setupARView()
                    arManager.loadSavedAnchors()
                }
                .onDisappear {
                    arManager.pauseSession()
                }
            
            // Status Indicator
            VStack {
                if !arManager.trackingState.isTracking || !arManager.sessionState.isTracking {
                    HStack {
                        if !arManager.sessionState.isTracking {
                            StatusView(state: arManager.sessionState, label: "Session")
                        }
                        if !arManager.trackingState.isTracking {
                            StatusView(state: arManager.trackingState, label: "Tracking")
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.top, 8)
                }
                Spacer()
            }
            
            // Bottom Controls
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: { showTutorial = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(selectedHabit?.wrappedName ?? "AR Habit Anchors")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { showHabitSelection = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                    }
                }
                .background(BlurView(style: .systemMaterial))
                
                Spacer()
                
                // Bottom Buttons
                VStack(spacing: 16) {
                    if isPlacingAnchor, let habit = selectedHabit {
                        Text("Tap to place \(habit.wrappedName)")
                            .font(.headline)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    HStack(spacing: 20) {
                        // Reset Button
                        Button(action: resetSession) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        
                        // Toggle Placement Button
                        Button(action: togglePlacement) {
                            HStack {
                                Image(systemName: isPlacingAnchor ? "xmark" : "plus.viewfinder")
                                Text(isPlacingAnchor ? "Cancel" : "Place Anchor")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPlacingAnchor ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(selectedHabit == nil && !isPlacingAnchor)
                        .opacity(selectedHabit == nil && !isPlacingAnchor ? 0.6 : 1.0)
                    }
                }
                .padding()
                .background(BlurView(style: .systemMaterial))
            }
            
            // Tutorial Overlay
            if showTutorial {
                ARTutorialView(isPresented: $showTutorial)
            }
            
            // Habit Selection
            if showHabitSelection {
                HabitSelectionView(selectedHabit: $selectedHabit, isPresented: $showHabitSelection) {
                    showHabitSelection = false
                    if selectedHabit != nil {
                        isPlacingAnchor = true
                    }
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(item: $anchorToDelete) { anchor in
            Alert(
                title: Text("Delete Anchor"),
                message: Text("Are you sure you want to delete this habit anchor?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAnchor(anchor)
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: arManager.sessionState) { state in
            if case let .failed(error) = state {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func togglePlacement() {
        if isPlacingAnchor {
            isPlacingAnchor = false
        } else if selectedHabit != nil {
            isPlacingAnchor = true
        } else {
            showHabitSelection = true
        }
    }
    
    private func resetSession() {
        arManager.resetSession()
        isPlacingAnchor = false
        selectedHabit = nil
    }
    
    private func handleAnchorTap(_ anchor: ARAnchor) {
        if isPlacingAnchor, let habit = selectedHabit {
            // Place new anchor
            arManager.placeAnchor(at: anchor.transform, for: habit)
            isPlacingAnchor = false
        } else if let _ = arManager.placedAnchors.first(where: { $0.value == anchor }) {
            // Show options for existing anchor
            anchorToDelete = anchor
            showDeleteAlert = true
        }
    }
    
    private func deleteAnchor(_ anchor: ARAnchor) {
        // Remove from AR session
        arManager.arView?.session.remove(anchor: anchor)
        
        // Delete from Core Data
        let fetchRequest: NSFetchRequest<ARAnchorEntity> = ARAnchorEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "anchorIdentifier == %@", anchor.identifier.uuidString)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            for entity in results {
                viewContext.delete(entity)
            }
            try viewContext.save()
        } catch {
            print("Error deleting anchor: \(error)")
        }
    }
    
    // MARK: - AR View Container
    struct ARViewContainer: UIViewRepresentable {
        @EnvironmentObject private var arManager: ARManager
        
        func makeUIView(context: Context) -> ARView {
            let arView = arManager.setupARView()
            setupGestures(on: arView)
            return arView
        }
        
        func updateUIView(_ uiView: ARView, context: Context) {}
        
        private func setupGestures(on arView: ARView) {
            let tapGesture = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
            )
            arView.addGestureRecognizer(tapGesture)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject {
            var parent: ARViewContainer
            
            init(_ parent: ARViewContainer) {
                self.parent = parent
                super.init()
            }
            
            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                guard let arView = gesture.view as? ARView else { return }
                
                let location = gesture.location(in: arView)
                
                // Check for existing anchors first
                if let hit = arView.hitTest(location, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first {
                    parent.arManager.handleAnchorTap(hit.anchor ?? ARAnchor(transform: hit.worldTransform))
                }
            }
        }
    }
}

// MARK: - Habit Selection View
private struct HabitSelectionView: View {
    @Binding var selectedHabit: Habit?
    @Binding var isPresented: Bool
    var onDismiss: () -> Void
    
    @EnvironmentObject private var habitManager: HabitManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select a Habit")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                Divider()
                
                // Habits List
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(habitManager.habits) { habit in
                            Button(action: {
                                selectedHabit = habit
                                isPresented = false
                                onDismiss()
                            }) {
                                HStack {
                                    Image(systemName: habit.wrappedIconName)
                                        .font(.title3)
                                        .foregroundColor(habit.color)
                                        .frame(width: 36, height: 36)
                                        .background(habit.color.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text(habit.wrappedName)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedHabit?.id == habit.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if habit.id != habitManager.habits.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                        
                        if habitManager.habits.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No Habits Yet")
                                    .font(.headline)
                                
                                Text("Add habits in the main screen to place AR anchors")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
        .background(
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                    onDismiss()
                }
        )
    }
}

// MARK: - Status View
private struct StatusView: View {
    let state: ARState
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundColor(state.isTracking ? .green : .yellow)
                .imageScale(.small)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                
                if !state.isTracking {
                    Text(state.statusMessage)
                        .font(.caption2)
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}

// MARK: - ARState Extension
private extension ARState {
    var isTracking: Bool {
        switch self {
        case .tracking(.normal):
            return true
        default:
            return false
        }
    }
    
    var statusMessage: String {
        switch self {
        case .initializing:
            return "Initializing..."
        case .tracking(.notAvailable):
            return "Not available"
        case .tracking(.limited(let reason)):
            switch reason {
            case .initializing:
                return "Initializing..."
            case .relocalizing:
                return "Relocalizing..."
            case .insufficientFeatures:
                return "Insufficient features"
            case .excessiveMotion:
                return "Too much movement"
            case .lowLight:
                return "Low light"
            @unknown default:
                return "Limited tracking"
            }
        case .failed(let error):
            return error.localizedDescription
        default:
            return ""
        }
    }
}

// MARK: - AR Tutorial View
private struct ARTutorialView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                Text("AR Habit Anchors")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    TutorialStep(icon: "1.circle.fill", title: "Select a Habit", description: "Tap the + button to choose a habit to place in your space")
                    
                    TutorialStep(icon: "2.circle.fill", title: "Find a Surface", description: "Move your device to detect flat surfaces in your environment")
                    
                    TutorialStep(icon: "3.circle.fill", title: "Place the Anchor", description: "Tap the screen to place the habit anchor in your space")
                    
                    TutorialStep(icon: "4.circle.fill", title: "Get Reminded", description: "Receive notifications when you're near your habit locations")
                }
                .padding()
                
                Button(action: { 
                    isPresented = false 
                    showHabitSelection = false
                    if selectedHabit != nil {
                        isPlacingAnchor = true
                    }
                }) {
                    Text("Got It!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding()
        }
    }
}

// MARK: - Tutorial Step View
private struct TutorialStep: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Blur View
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
