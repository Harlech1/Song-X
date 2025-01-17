import SwiftUI
import TPackage

@MainActor
class CreditsManager: ObservableObject {
    static let shared = CreditsManager()
    
    @AppStorage("dailyEditCount") private var dailyEditCount: Int = 0
    @AppStorage("lastEditDate") private var lastEditDate: Double = Date().timeIntervalSince1970
    
    let maxDailyEdits = 2
    
    init() {
        resetDailyCountIfNeeded()
    }
    
    var remainingCredits: Int {
        maxDailyEdits - dailyEditCount
    }
    
    func canEditMoreSongs(premiumManager: TKPremiumManager) -> Bool {
        if premiumManager.isPremium { return true }
        resetDailyCountIfNeeded()
        return dailyEditCount < maxDailyEdits
    }
    
    func incrementDailyCount(premiumManager: TKPremiumManager) {
        if !premiumManager.isPremium {
            dailyEditCount += 1
        }
    }
    
    private func resetDailyCountIfNeeded() {
        let calendar = Calendar.current
        let lastDate = Date(timeIntervalSince1970: lastEditDate)
        let now = Date()
        
        if !calendar.isDate(lastDate, inSameDayAs: now) {
            dailyEditCount = 0
            lastEditDate = now.timeIntervalSince1970
        }
    }
} 