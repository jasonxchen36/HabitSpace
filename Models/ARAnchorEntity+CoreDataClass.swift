import Foundation
import CoreData
import ARKit

@objc(ARAnchorEntity)
public class ARAnchorEntity: NSManagedObject {
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedAnchorIdentifier: String { anchorIdentifier ?? "" }
    public var wrappedCreatedAt: Date { createdAt ?? Date() }
    
    public var position: SIMD3<Float> {
        get {
            return SIMD3<Float>(
                Float(positionX),
                Float(positionY),
                Float(positionZ)
            )
        }
        set {
            positionX = Double(newValue.x)
            positionY = Double(newValue.y)
            positionZ = Double(newValue.z)
        }
    }
    
    public var rotation: simd_quatf {
        get {
            return simd_quatf(
                ix: Float(rotationX),
                iy: Float(rotationY),
                iz: Float(rotationZ),
                r: Float(rotationW)
            )
        }
        set {
            rotationX = Double(newValue.vector.x)
            rotationY = Double(newValue.vector.y)
            rotationZ = Double(newValue.vector.z)
            rotationW = Double(newValue.vector.w)
        }
    }
    
    public func update(from anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        position = SIMD3<Float>(
            anchor.center.x,
            anchor.center.y,
            anchor.center.z
        )
        // For plane anchors, we'll use the plane's orientation
        let orientation = simd_quatf(anchor.transform)
        rotation = orientation
        lastUpdated = Date()
    }
    
    public func createARAnchor() -> ARAnchor? {
        let transform = simd_float4x4(
            rotation * simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0)),
            position
        )
        let anchor = ARAnchor(name: wrappedAnchorIdentifier, transform: transform)
        return anchor
    }
}

extension ARAnchorEntity {
    static var preview: ARAnchorEntity {
        let entity = ARAnchorEntity(context: CoreDataManager.preview.container.viewContext)
        entity.id = UUID()
        entity.anchorIdentifier = "preview-anchor"
        entity.positionX = 0
        entity.positionY = 0
        entity.positionZ = -0.5
        entity.rotationX = 0
        entity.rotationY = 0
        entity.rotationZ = 0
        entity.rotationW = 1
        entity.createdAt = Date()
        entity.lastUpdated = Date()
        return entity
    }
}
