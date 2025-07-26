import SwiftUI
import TPackage

@MainActor
class CreditsManager: ObservableObject {
    static let shared = CreditsManager()
    
    @AppStorage("freeSongCredits") private var freeSongCredits: Int = 2
    @AppStorage("lastResetDate") private var lastResetDate: Double = Date().timeIntervalSince1970
    
    let maxFreeSongsPerDay = 2
    
    init() {
        resetCreditsIfNewDay()
        
        // Add observer for when app becomes active
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(appDidBecomeActive),
                                             name: UIApplication.didBecomeActiveNotification,
                                             object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var remainingFreeSongs: Int {
        resetCreditsIfNewDay()  // Check for reset when accessing
        return freeSongCredits
    }
    
    func canEditSong(premiumManager: TKPremiumManager) -> Bool {
        if premiumManager.isPremium { return true }
        resetCreditsIfNewDay()
        return freeSongCredits > 0
    }
    
    func useCredit(premiumManager: TKPremiumManager) {
        if !premiumManager.isPremium {
            freeSongCredits = max(0, freeSongCredits - 1)
            lastResetDate = Date().timeIntervalSince1970
        }
    }
    
    @objc private func appDidBecomeActive() {
        resetCreditsIfNewDay()
    }
    
    private func resetCreditsIfNewDay() {
        let calendar = Calendar.current
        let lastReset = Date(timeIntervalSince1970: lastResetDate)
        let now = Date()
        
        // Get start of today and start of last reset day
        guard let todayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
              let lastResetStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: lastReset) else {
            return
        }
        
        // If last reset was before today's start, reset credits
        if lastResetStart < todayStart {
            freeSongCredits = maxFreeSongsPerDay
            lastResetDate = now.timeIntervalSince1970
        }
    }
} 