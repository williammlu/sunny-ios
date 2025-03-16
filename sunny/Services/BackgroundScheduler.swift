import BackgroundTasks
import UserNotifications

/// Manages BGTask registration + scheduling a local notification
/// after ~15 minutes if the user hasn't finished the session.
struct BackgroundScheduler {
    static let sunTaskID = "com.sunny.scheduleSunTask"
    
    /// Call this once at app launch (e.g., in sunnyApp.swift)
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: sunTaskID, using: nil) { task in
            handleSunTask(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Schedule the BG task to run in X minutes.
    static func scheduleSunTask(inMinutes: Int) {
        do {
            let request = BGAppRefreshTaskRequest(identifier: sunTaskID)
            request.earliestBeginDate = Date().addingTimeInterval(TimeInterval(inMinutes * 60))
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled BGAppRefreshTask in ~\(inMinutes) min.")
        } catch {
            print("Failed to schedule BG task: \(error)")
        }
    }
    
    private static func handleSunTask(task: BGAppRefreshTask) {
        // Provide an expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // If user never reopened or ended => send local push
        sendLocalNotification(
            title: "Sunshine Complete!",
            body: "Your 15-minute session has ended."
        )
        
        // Done
        task.setTaskCompleted(success: true)
    }
    
    private static func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "sunny_completed",
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { err in
            if let err = err {
                print("Error scheduling local notification: \(err)")
            }
        }
    }
}
