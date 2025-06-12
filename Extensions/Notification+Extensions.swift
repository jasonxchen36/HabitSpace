import Foundation

extension Notification.Name {
    /// Notification sent when an AR anchor is tapped in the ARView
    static let didTapARAnchor = Notification.Name("didTapARAnchor")
}

// MARK: - Notification UserInfo Keys
extension Notification {
    struct UserInfoKey {
        static let anchor = "anchor"
    }
    
    var anchor: ARAnchor? {
        return userInfo?[UserInfoKey.anchor] as? ARAnchor
    }
}
