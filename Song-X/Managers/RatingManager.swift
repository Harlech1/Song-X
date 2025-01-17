import SwiftUI
import StoreKit

@MainActor
final class RatingManager: ObservableObject {
    static let shared = RatingManager()
    
    @AppStorage("hasShownRating") private var hasShownRating = false
    @AppStorage("generationCount") private var generationCount = 0
    
    func incrementGenerationCount() {
        generationCount += 1
    }
    
    func showRatingIfNeeded() {
        guard !hasShownRating else { return }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if generationCount == 1 {
                await requestReview()
                hasShownRating = true
            }
        }
    }
    
    func requestReview() async {
        await SKStoreReviewController.requestReview()
    }
}
