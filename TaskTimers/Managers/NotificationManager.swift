import Foundation
import UserNotifications

/// Handles all notification related logic for the timer experience.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                #if DEBUG
                print("Notification permission error: \(error.localizedDescription)")
                #endif
            }
            if granted {
                self.registerCategories()
            }
        }
    }

    func scheduleTimerCompletionNotification(taskName: String, fireDate: Date?) {
        cancelPendingNotifications()
        guard let fireDate, fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time's Up"
        content.body = "\(taskName) has finished."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("timer_end.mp3"))
        content.categoryIdentifier = "timer.complete"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                #if DEBUG
                print("Failed to schedule notification: \(error.localizedDescription)")
                #endif
            }
        }
    }

    func cancelPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func sendCompletionNow(taskName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time's Up"
        content.body = "\(taskName) finished."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("timer_end.mp3"))
        content.categoryIdentifier = "timer.complete"

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }

    func checkNotificationSettings(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner, .list])
    }

    private func registerCategories() {
        let doneAction = UNNotificationAction(identifier: "timer.complete.dismiss", title: "OK", options: [.foreground])
        let category = UNNotificationCategory(identifier: "timer.complete", actions: [doneAction], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }
}
