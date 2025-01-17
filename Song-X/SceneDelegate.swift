import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        ShortcutManager.shared.shortcutItem = shortcutItem
        ShortcutManager.shared.handleShortcut()
        completionHandler(true)
    }
} 