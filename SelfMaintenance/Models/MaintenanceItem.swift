import Foundation
import SwiftData

@Model
final class MaintenanceItem {
    var id: UUID
    var name: String
    var presetKey: String?
    var carePartRaw: String
    var intervalValue: Int
    var intervalUnitRaw: String
    var notificationEnabled: Bool
    var notificationTimingRaw: String
    var customNextDueDate: Date?
    var deferUntil: Date?
    var memo: String
    var isHidden: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceLog.item)
    var logs: [MaintenanceLog]

    init(
        id: UUID = UUID(),
        name: String,
        presetKey: String? = nil,
        carePart: CarePart,
        intervalValue: Int,
        intervalUnit: IntervalUnit,
        notificationEnabled: Bool = true,
        notificationTiming: NotificationTiming = .soonStart,
        customNextDueDate: Date? = nil,
        deferUntil: Date? = nil,
        memo: String = "",
        isHidden: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        logs: [MaintenanceLog] = []
    ) {
        self.id = id
        self.name = name
        self.presetKey = presetKey
        self.carePartRaw = carePart.rawValue
        self.intervalValue = intervalValue
        self.intervalUnitRaw = intervalUnit.rawValue
        self.notificationEnabled = notificationEnabled
        self.notificationTimingRaw = notificationTiming.rawValue
        self.customNextDueDate = customNextDueDate
        self.deferUntil = deferUntil
        self.memo = memo
        self.isHidden = isHidden
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.logs = logs
    }

    var carePart: CarePart {
        get { CarePart(rawValue: carePartRaw) ?? .other }
        set { carePartRaw = newValue.rawValue }
    }

    var intervalUnit: IntervalUnit {
        get { IntervalUnit(rawValue: intervalUnitRaw) ?? .month }
        set { intervalUnitRaw = newValue.rawValue }
    }

    var notificationTiming: NotificationTiming {
        get { NotificationTiming(rawValue: notificationTimingRaw) ?? .soonStart }
        set { notificationTimingRaw = newValue.rawValue }
    }

    var latestLog: MaintenanceLog? {
        logs.max { $0.performedAt < $1.performedAt }
    }

    var visibleLogs: [MaintenanceLog] {
        logs.sorted { $0.performedAt > $1.performedAt }
    }
}
