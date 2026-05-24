import Foundation

struct MaintenanceStatusInfo {
    let status: MaintenanceStatus
    let dueDate: Date?
    let daysDifference: Int?
    let soonStartDays: Int

    var displayText: String {
        switch status {
        case .unrecorded:
            return MaintenanceStatus.unrecorded.rawValue
        case .plenty:
            if let daysDifference {
                return "あと\(daysDifference)日"
            }
            return MaintenanceStatus.plenty.rawValue
        case .soon:
            return MaintenanceStatus.soon.rawValue
        case .nearDue:
            return MaintenanceStatus.nearDue.rawValue
        case .overdue:
            return "\(abs(daysDifference ?? 0))日過ぎています"
        case .deferred:
            return MaintenanceStatus.deferred.rawValue
        }
    }
}

enum MaintenanceStatusService {
    static func nextDueDate(for item: MaintenanceItem, calendar: Calendar = .current) -> Date? {
        if let customNextDueDate = item.customNextDueDate {
            return calendar.startOfDay(for: customNextDueDate)
        }

        guard let latest = item.latestLog else {
            return nil
        }

        return calendar.date(
            byAdding: dateComponent(for: item.intervalUnit, value: item.intervalValue),
            to: calendar.startOfDay(for: latest.performedAt)
        )
    }

    static func statusInfo(for item: MaintenanceItem, today: Date = Date(), calendar: Calendar = .current) -> MaintenanceStatusInfo {
        let todayStart = calendar.startOfDay(for: today)
        let soonDays = soonStartDays(for: item)

        if let deferUntil = item.deferUntil, calendar.startOfDay(for: deferUntil) >= todayStart {
            return MaintenanceStatusInfo(status: .deferred, dueDate: nextDueDate(for: item, calendar: calendar), daysDifference: nil, soonStartDays: soonDays)
        }

        guard let dueDate = nextDueDate(for: item, calendar: calendar) else {
            return MaintenanceStatusInfo(status: .unrecorded, dueDate: nil, daysDifference: nil, soonStartDays: soonDays)
        }

        let dueStart = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: todayStart, to: dueStart).day ?? 0

        if days < -2 {
            return MaintenanceStatusInfo(status: .overdue, dueDate: dueStart, daysDifference: days, soonStartDays: soonDays)
        }

        if (-2...3).contains(days) {
            return MaintenanceStatusInfo(status: .nearDue, dueDate: dueStart, daysDifference: days, soonStartDays: soonDays)
        }

        if days <= soonDays {
            return MaintenanceStatusInfo(status: .soon, dueDate: dueStart, daysDifference: days, soonStartDays: soonDays)
        }

        return MaintenanceStatusInfo(status: .plenty, dueDate: dueStart, daysDifference: days, soonStartDays: soonDays)
    }

    static func sortKey(for item: MaintenanceItem, today: Date = Date(), calendar: Calendar = .current) -> (Int, Int, Date) {
        let info = statusInfo(for: item, today: today, calendar: calendar)
        let priority: Int

        switch info.status {
        case .overdue: priority = 0
        case .nearDue: priority = 1
        case .soon: priority = 2
        case .plenty: priority = 3
        case .deferred: priority = 4
        case .unrecorded: priority = 5
        }

        let distance = info.status == .overdue ? -(info.daysDifference ?? 0) : (info.daysDifference ?? Int.max)
        return (priority, distance, info.dueDate ?? item.createdAt)
    }

    static func soonStartDays(for item: MaintenanceItem) -> Int {
        let intervalDays = max(1, intervalDays(value: item.intervalValue, unit: item.intervalUnit))
        let raw = Int((Double(intervalDays) * 0.2).rounded())
        return min(30, max(7, raw))
    }

    static func notificationDate(for item: MaintenanceItem, hour: Int, minute: Int, calendar: Calendar = .current) -> Date? {
        guard item.notificationEnabled, item.notificationTiming != .none, let due = nextDueDate(for: item, calendar: calendar) else {
            return nil
        }

        let offset: Int
        switch item.notificationTiming {
        case .none: return nil
        case .dueDay: offset = 0
        case .threeDaysBefore: offset = -3
        case .sevenDaysBefore: offset = -7
        case .fourteenDaysBefore: offset = -14
        case .thirtyDaysBefore: offset = -30
        case .soonStart: offset = -soonStartDays(for: item)
        }

        guard let day = calendar.date(byAdding: .day, value: offset, to: due) else {
            return nil
        }

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    private static func dateComponent(for unit: IntervalUnit, value: Int) -> DateComponents {
        switch unit {
        case .day: DateComponents(day: value)
        case .week: DateComponents(day: value * 7)
        case .month: DateComponents(month: value)
        case .year: DateComponents(year: value)
        }
    }

    private static func intervalDays(value: Int, unit: IntervalUnit) -> Int {
        switch unit {
        case .day: value
        case .week: value * 7
        case .month: value * 30
        case .year: value * 365
        }
    }
}
