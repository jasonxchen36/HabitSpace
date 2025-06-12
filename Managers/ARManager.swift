import ARKit
import RealityKit
import Combine

class ARManager: NSObject, ObservableObject {
    static let shared = ARManager()
    
    // Published properties
    @Published var arView: ARView?
    @Published var sessionState: ARState = .initializing
    @Published var trackingState: ARState = .initializing
    @Published var currentAnchor: ARAnchor?
    @Published var placedAnchors: [ARAnchor] = []
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private let coreDataManager = CoreDataManager.shared
    private var arSession: ARSession {
        return arView?.session ?? ARSession()
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupBindings()
    }
    
    // MARK: - Setup
    func setupARView() -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        arView.session.delegate = self
        
        // Setup coaching overlay
        setupCoachingOverlay(for: arView)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        self.arView = arView
        return arView
    }
    
    private func setupBindings() {
        $sessionState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AR Session Management
    func resetSession() {
        guard let config = arView?.session.configuration else { return }
        arView?.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func pauseSession() {
        arView?.session.pause()
    }
    
    // MARK: - Anchor Management
    
    func handleAnchorTap(_ anchor: ARAnchor) {
        // This method is called when an anchor is tapped in the ARView
        // The actual handling is done in ARHabitView
        NotificationCenter.default.post(name: .didTapARAnchor, object: nil, userInfo: ["anchor": anchor])
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        
        // First check if we hit an existing anchor
        if let hitResult = arView.hitTest(location, options: [.boundingBoxOnly: true]).first,
           let anchor = hitResult.entity.anchor as? ARAnchor {
            handleAnchorTap(anchor)
            return
        }
        
        // If no anchor was hit, perform a hit test against planes
        let hitTestResults = arView.hitTest(location, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
        if let hitResult = hitTestResults.first {
            // Create a temporary anchor at the hit location
            let anchor = ARAnchor(transform: hitResult.worldTransform)
            handleAnchorTap(anchor)
        }
    }
    
    func placeAnchor(at transform: simd_float4x4, for habit: Habit) {
        guard let arView = arView else { return }
        
        // Create anchor with a unique name
        let anchorName = "habit_\(habit.wrappedId.uuidString)_\(UUID().uuidString.prefix(8))"
        let anchor = ARAnchor(name: anchorName, transform: transform)
        
        // Add anchor to the session
        arView.session.add(anchor: anchor)
        
        // Save anchor to Core Data
        saveAnchor(anchor, for: habit)
        
        // Add to placed anchors
        placedAnchors.append(anchor)
        
        // Visualize the anchor
        visualizeAnchor(anchor, for: habit, in: arView)
    }
    
    private func saveAnchor(_ anchor: ARAnchor, for habit: Habit) {
        let entity = ARAnchorEntity(context: coreDataManager.context)
        entity.id = UUID()
        entity.habitId = habit.wrappedId
        entity.anchorIdentifier = anchor.identifier.uuidString
        entity.position = SIMD3<Float>(
            anchor.transform.columns.3.x,
            anchor.transform.columns.3.y,
            anchor.transform.columns.3.z
        )
        
        // Extract rotation from transform
        let rotation = simd_quatf(anchor.transform)
        entity.rotation = rotation
        
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
    }
    
    // MARK: - Load Saved Anchors
    func loadSavedAnchors() {
        guard let arView = arView else { return }
        
        // Clear existing anchors
        arView.scene.anchors.removeAll()
        
        // Fetch all saved anchors
        let fetchRequest: NSFetchRequest<ARAnchorEntity> = ARAnchorEntity.fetchRequest()
        
        do {
            let savedAnchors = try coreDataManager.context.fetch(fetchRequest)
            
            for savedAnchor in savedAnchors {
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
                arView.session.add(anchor: anchor)
                
                // Visualize
                if let habit = try? coreDataManager.context.existingObject(with: savedAnchor.habitId) as? Habit {
                    visualizeAnchor(anchor, for: habit, in: arView)
                }
            }
        } catch {
            print("Failed to load saved anchors: \(error)")
        }
    }
    
    // MARK: - Coaching Overlay
    private func setupCoachingOverlay(for arView: ARView) {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.session = arView.session
        arView.addSubview(coachingOverlay)
    }
}

// MARK: - ARSessionDelegate
extension ARManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            self.trackingState = .tracking(frame.camera.trackingState)
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        DispatchQueue.main.async {
            self.placedAnchors.append(contentsOf: anchors)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.sessionState = .failed(error)
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
extension ARManager {
    static var preview: ARManager {
        let manager = ARManager()
        manager.sessionState = .normal
        manager.trackingState = .tracking(.normal)
        return manager
    }
}
