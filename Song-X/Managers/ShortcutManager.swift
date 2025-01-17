import SwiftUI

class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var shortcutItem: UIApplicationShortcutItem?
    @Published var showWishKit = false
    @Published var showSpecialOffer = false
    
    private init() {}
    
    func handleShortcut() {
        guard let shortcut = shortcutItem else { return }
        
        switch shortcut.type {
        case "wishkit-action":
            showWishKit = true
        case "offer-action":
            showSpecialOffer = true
        default:
            break
        }
    }
} 