import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    static func schedule(item: MaintenanceItem, hour: Int, minute: Int) async {
        cancel(item: item)

        guard !item.isHidden,
              let date = MaintenanceStatusService.notificationDate(for: item, hour: hour, minute: minute),
              date > Date(),
              await requestAuthorizationIfNeeded()
        else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "そろそろメンテナンスの時期です"
        content.body = "\(item.name)の目安日が近づいています。"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: item), content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(item: MaintenanceItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: item)])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func identifier(for item: MaintenanceItem) -> String {
        "maintenance-\(item.id.uuidString)"
    }
}
