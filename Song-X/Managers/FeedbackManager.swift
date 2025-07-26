import Foundation
import SwiftUI
import RevenueCat

@MainActor
class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @AppStorage("hasGivenFirstFeedback") private var hasGivenFirstFeedback = false
    @AppStorage("lastFeedbackDate") private var lastFeedbackDate: Double = Date().timeIntervalSince1970
    @AppStorage("isFirstTimeUser") private var isFirstTimeUser = true
    
    @Published var showingFeedback = false
    @Published var feedbackText = ""
    
    private init() {}
    
    func checkAndShowFeedback() {
        let now = Date().timeIntervalSince1970
        let twoWeeksInSeconds: TimeInterval = 14 * 24 * 60 * 60
        let timeSinceLastFeedback = now - lastFeedbackDate
        
        if (isFirstTimeUser && !hasGivenFirstFeedback) ||
            (!isFirstTimeUser && timeSinceLastFeedback >= twoWeeksInSeconds) {
            showingFeedback = true
            hasGivenFirstFeedback = true
            isFirstTimeUser = false
        }
    }
    
    func sendFeedback(wasCanceled: Bool, source: String) {
        // Update last feedback date when feedback is sent
        if !wasCanceled {
            lastFeedbackDate = Date().timeIntervalSince1970
        }
        
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                let isPremium = customerInfo.entitlements.all["Premium"]?.isActive == true
                let originalAppUserId = customerInfo.originalAppUserId
                let firstSeen = customerInfo.firstSeen
                let latestExpirationDate = customerInfo.latestExpirationDate
                
                let locale = Locale.current
                let countryCode = locale.region?.identifier ?? "Unknown"
                let language = locale.language.languageCode?.identifier ?? "Unknown"
                
                let timezone = TimeZone.current.identifier
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone.current
                let localTime = dateFormatter.string(from: Date())
                
                let feedbackData: [String: Any] = [
                    "feedback": feedbackText.trimmingCharacters(in: .whitespacesAndNewlines),
                    "device": UIDevice.current.model,
                    "systemVersion": UIDevice.current.systemVersion,
                    "isPremium": isPremium,
                    "originalAppUserId": originalAppUserId,
                    "firstSeen": firstSeen.description,
                    "latestExpirationDate": latestExpirationDate?.description ?? "N/A",
                    "country": countryCode,
                    "language": language,
                    "timezone": timezone,
                    "localTime": localTime,
                    "source": source,
                    "wasCanceled": wasCanceled,
                    "feedbackAction": wasCanceled ? "Canceled" : "Sent"
                ]
                
                guard let url = URL(string: "https://api.turkerkizilcik.com/feedback/"),
                      let jsonData = try? JSONSerialization.data(withJSONObject: feedbackData) else {
                    print("Error creating URL or JSON data")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                request.timeoutInterval = 30
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Feedback info sent successfully")
                        if !wasCanceled {
                            feedbackText = ""
                            showingFeedback = false
                        }
                    } else {
                        print("Error sending feedback. Status code: \(httpResponse.statusCode)")
                    }
                }
            } catch {
                print("Error sending feedback: \(error)")
            }
        }
    }
} 