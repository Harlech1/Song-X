import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func scheduleNotifications() {
        // Remove any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 1 hour notification
        scheduleNotification(
            identifier: "1hour",
            title: "Miss creating music?",
            body: "Come back and create your next remix!",
            timeInterval: 3600 // 1 hour in seconds
        )
        
        // 1 day notification
        scheduleNotification(
            identifier: "1day",
            title: "Your music awaits!",
            body: "Don't forget to check out our premium features for unlimited remixes.",
            timeInterval: 86400 // 24 hours in seconds
        )
        
        // 1 week notification
        scheduleNotification(
            identifier: "1week",
            title: "Time for a new remix?",
            body: "Create unlimited remixes with premium features!",
            timeInterval: 604800 // 1 week in seconds
        )
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, timeInterval: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
} 