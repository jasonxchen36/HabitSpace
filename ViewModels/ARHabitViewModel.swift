import Foundation
import ARKit
import RealityKit
import CoreData
import Combine

@MainActor
class ARHabitViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var arView: ARView?
    @Published var sessionState: ARState = .initializing
    @Published var trackingState: ARState = .initializing
    @Published var isPlacingAnchor = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var selectedHabit: Habit?
    @Published var showHabitSelection = false
    @Published var showTutorial = true
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let arSession = ARSession()
    private let coreDataManager = CoreDataManager.shared
    private let notificationManager = NotificationManager.shared
    private var placedAnchors: [ARAnchor: Habit] = [:]
    private var anchorEntities: [UUID: AnchorEntity] = [:] // Track anchor entities by habit ID
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func setupARView() -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session = arSession
        arSession.delegate = self
        arSession.run(config)
        
        // Setup coaching overlay
        setupCoachingOverlay(for: arView)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        self.arView = arView
        return arView
    }
    
    func loadSavedAnchors() {
        guard let arView = arView else { return }
        
        // Clear existing anchors
        arView.scene.anchors.removeAll()
        placedAnchors.removeAll()
        anchorEntities.removeAll()
        
        // Fetch all saved anchors
        let fetchRequest: NSFetchRequest<ARAnchorEntity> = ARAnchorEntity.fetchRequest()
        
        do {
            let savedAnchors = try coreDataManager.context.fetch(fetchRequest)
            
            for savedAnchor in savedAnchors {
                guard let habit = savedAnchor.habit else { continue }
                
                // Create ARAnchor
                let transform = simd_float4x4(
                    simd_quatf(
                        ix: Float(savedAnchor.rotationX),
                        iy: Float(savedAnchor.rotationY),
                        iz: Float(savedAnchor.rotationZ),
                        r: Float(savedAnchor.rotationW)
                    ),
                    SIMD3<Float>(
                        Float(savedAnchor.positionX),
                        Float(savedAnchor.positionY),
                        Float(savedAnchor.positionZ)
                    )
                )
                
                let anchor = ARAnchor(
                    name: "habit_\(savedAnchor.wrappedHabitId.uuidString)",
                    transform: transform
                )
                
                // Add to session
                arSession.add(anchor: anchor)
                placedAnchors[anchor] = habit
                
                // Visualize
                visualizeAnchor(anchor, for: habit, in: arView)
            }
        } catch {
            alertMessage = "Failed to load saved anchors: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    func startPlacingAnchor(for habit: Habit) {
        selectedHabit = habit
        isPlacingAnchor = true
    }
    
    func resetSession() {
        arSession.run(ARWorldTrackingConfiguration())
        isPlacingAnchor = false
        selectedHabit = nil
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        $sessionState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupCoachingOverlay(for arView: ARView) {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.session = arView.session
        arView.addSubview(coachingOverlay)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView,
              isPlacingAnchor,
              let habit = selectedHabit else { return }
        
        let location = gesture.location(in: arView)
        
        // Perform hit test against existing anchors first
        if let anchor = arView.hitTest(location, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first {
            placeAnchor(at: anchor.worldTransform, for: habit)
        }
    }
    
    private func placeAnchor(at transform: simd_float4x4, for habit: Habit) {
        guard let arView = arView else { return }
        
        // Create anchor
        let anchor = ARAnchor(name: "habit_\(habit.wrappedId.uuidString)", transform: transform)
        
        // Add anchor to the session
        arSession.add(anchor: anchor)
        placedAnchors[anchor] = habit
        
        // Save anchor to Core Data
        saveAnchor(anchor, for: habit)
        
        // Visualize the anchor
        visualizeAnchor(anchor, for: habit, in: arView)
        
        // Reset placement state
        isPlacingAnchor = false
        selectedHabit = nil
    }
    
    private func saveAnchor(_ anchor: ARAnchor, for habit: Habit) {
        let entity = ARAnchorEntity(context: coreDataManager.context)
        entity.id = UUID()
        entity.habitId = habit.wrappedId
        entity.anchorIdentifier = anchor.identifier.uuidString
        
        // Extract position and rotation from transform
        let position = anchor.transform.columns.3
        entity.positionX = Double(position.x)
        entity.positionY = Double(position.y)
        entity.positionZ = Double(position.z)
        
        let rotation = simd_quatf(anchor.transform)
        entity.rotationX = Double(rotation.vector.x)
        entity.rotationY = Double(rotation.vector.y)
        entity.rotationZ = Double(rotation.vector.z)
        entity.rotationW = Double(rotation.vector.w)
        
        coreDataManager.saveContext()
    }
    
    private func visualizeAnchor(_ anchor: ARAnchor, for habit: Habit, in arView: ARView) {
        // Create a simple sphere to represent the habit
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: habit.uiColor.withAlphaComponent(0.8), isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Add an icon on top
        let textMesh = MeshResource.generateText(
            habit.wrappedIconName,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.1),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = [0, 0.1, 0]
        entity.addChild(textEntity)
        
        // Create anchor entity
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        
        // Add to scene
        arView.scene.addAnchor(anchorEntity)
        
        // Store reference
        anchorEntities[habit.wrappedId] = anchorEntity
    }
    
    private func removeAnchor(for habit: Habit) {
        guard let entity = anchorEntities[habit.wrappedId] else { return }
        
        // Remove from AR view
        arView?.scene.removeAnchor(entity)
        
        // Remove from Core Data
        let fetchRequest: NSFetchRequest<ARAnchorEntity> = ARAnchorEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "habitId == %@", habit.wrappedId as CVarArg)
        
        do {
            let results = try coreDataManager.context.fetch(fetchRequest)
            for entity in results {
                coreDataManager.context.delete(entity)
            }
            try coreDataManager.context.save()
        } catch {
            alertMessage = "Failed to delete anchor: \(error.localizedDescription)"
            showAlert = true
        }
        
        // Remove from local storage
        anchorEntities.removeValue(forKey: habit.wrappedId)
        placedAnchors = placedAnchors.filter { $0.value.wrappedId != habit.wrappedId }
    }
}

// MARK: - ARSessionDelegate

extension ARHabitViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            self.trackingState = .tracking(frame.camera.trackingState)
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle new anchors if needed
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.sessionState = .failed(error)
            self.alertMessage = error.localizedDescription
            self.showAlert = true
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.sessionState = .interrupted
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.sessionState = .normal
            self.resetSession()
        }
    }
}

// MARK: - AR State

enum ARState: Equatable {
    case initializing
    case normal
    case limited(reason: ARFrame.WorldMappingStatus)
    case tracking(ARTrackingState)
    case interrupted
    case failed(Error)
    
    var isTracking: Bool {
        if case .tracking = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case let .failed(error) = self {
            return error.localizedDescription
        }
        return nil
    }
    
    static func == (lhs: ARState, rhs: ARState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing):
            return true
        case (.normal, .normal):
            return true
        case let (.limited(lhsReason), .limited(rhsReason)):
            return lhsReason == rhsReason
        case let (.tracking(lhsState), .tracking(rhsState)):
            return lhsState == rhsState
        case (.interrupted, .interrupted):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Preview Helper

extension ARHabitViewModel {
    static var preview: ARHabitViewModel {
        let viewModel = ARHabitViewModel()
        viewModel.sessionState = .normal
        viewModel.trackingState = .tracking(.normal)
        return viewModel
    }
}
