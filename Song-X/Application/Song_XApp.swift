//
//  Song_XApp.swift
//  Song-X
//
//  Created by Türker Kızılcık on 21.09.2024.
//

import SwiftUI
import RevenueCat
import RevenueCatUI
import TPackage
import WishKit

@main
struct Song_XApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var premiumManager = TKPremiumManager.shared
    @StateObject var shortcutManager = ShortcutManager.shared

    init() {
        SongManager.shared.setup()
        TPackage.configure(withAPIKey: "appl_RLmJgqCyzfRwzwveRMeiklWBzFS", entitlementIdentifier: "Premium")
        WishKit.configure(with: "3FEB226B-1462-4D39-8555-9C6106279883")
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(premiumManager)
                .environmentObject(shortcutManager)
        }
    }
}

// Add window shortcuts modifier
extension Scene {
    func windowShortcuts(shortcutManager: ShortcutManager) -> some Scene {
        self.onChange(of: shortcutManager.shortcutItem) { shortcut in
            shortcutManager.handleShortcut()
        }
    }
}
