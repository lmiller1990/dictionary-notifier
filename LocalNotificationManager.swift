import UserNotifications
import SwiftUI
import CoreData


struct Notification {
    var title: String
}

class LocalNotificationManager {
    var notifications = [Notification]()
    var notificationFrequencies = [Double]()

    func setNotificationFrequencies(frequencies: [Double]) {
        print("Setting frequencies to \(frequencies)")
        self.notificationFrequencies = frequencies
    }
    
    func requestPermission() -> Void {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .badge, .alert]) { granted, error in
                if granted == true && error == nil {
                    print("Got Permission")
                    self.schedule()
                    // We have permission!
                } else {
                    print("Did not get permission")
                }
        }
    }
    
    func addNotification(title: String) -> Void {
        notifications.append(Notification(title: title))
    }
    
    func testNotification() {
        UNUserNotificationCenter
        .current()
        .requestAuthorization(options: [.alert, .badge, .alert]) { granted, error in
            if granted == true && error == nil {
                print("Got Permission")
            } else {
                // ...
            }
        }
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                print("Error scheduling test notification")
            }
            
            guard error == nil else { return }
            print("Scheduled test notification")
        }
    }
    
    func schedule() -> Void {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                print("Requesting Permission")
                self.requestPermission()
            case .authorized, .provisional:
                print("Schueduling Notifications")
                self.scheduleNotifications()
            default:
                break
            }
        }
    }
        
    func scheduleNotifications() -> Void {
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            print("Frequencies", notificationFrequencies)
             for i in notificationFrequencies {
                // make the notifications a bit more random to space them out.
                // 300.. 21600 is 5 min -> 6 hours
                let randomHours = Double.random(in: 300...21600)
                let id = UUID()
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: i + randomHours, repeats: false)
                let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if error != nil {
                        print("error", error.debugDescription)
                    }
                    
                    guard error == nil else { return }
                    print("Scheduling notification with id: \(id)")
                }
            }
            notifications = []
        }
    }
}
