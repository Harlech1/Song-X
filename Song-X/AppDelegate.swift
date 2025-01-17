import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            ShortcutManager.shared.shortcutItem = shortcutItem
            // Handle the shortcut immediately when app launches
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ShortcutManager.shared.handleShortcut()
            }
        }
        
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    // Handle when app launches from terminated state
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            ShortcutManager.shared.shortcutItem = shortcutItem
            // Small delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ShortcutManager.shared.handleShortcut()
            }
            return false
        }
        return true
    }
} 