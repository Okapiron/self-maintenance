import Foundation

enum SpendingPeriod: String, CaseIterable, Identifiable {
    case month = "今月"
    case yearToDate = "今年"
    case rollingYear = "1年"
    case all = "全て"

    var id: String { rawValue }
}

struct SpendingBreakdown: Identifiable {
    let id: String
    let title: String
    let amount: Int
}

enum SpendingSummaryService {
    static func logs(in period: SpendingPeriod, from items: [MaintenanceItem], now: Date = Date(), calendar: Calendar = .current) -> [MaintenanceLog] {
        let allLogs = items
            .filter { !$0.isHidden }
            .flatMap(\.logs)
        guard let range = dateRange(for: period, now: now, calendar: calendar) else {
            return allLogs
        }
        return allLogs.filter { range.contains(calendar.startOfDay(for: $0.performedAt)) }
    }

    static func total(for logs: [MaintenanceLog]) -> Int {
        logs.compactMap(\.amount).reduce(0, +)
    }

    static func byItem(for items: [MaintenanceItem], logs: [MaintenanceLog]) -> [SpendingBreakdown] {
        let grouped = Dictionary(grouping: logs.filter { $0.amount != nil }) { $0.item?.id.uuidString ?? "unknown" }
        return grouped.compactMap { key, logs in
            guard let item = items.first(where: { !$0.isHidden && $0.id.uuidString == key }) else {
                return nil
            }
            return SpendingBreakdown(id: key, title: item.name, amount: total(for: logs))
        }
        .sorted { $0.amount > $1.amount }
    }

    static func byCarePart(for logs: [MaintenanceLog]) -> [SpendingBreakdown] {
        let grouped = Dictionary(grouping: logs.filter { $0.amount != nil }) { $0.item?.carePart ?? .other }
        return grouped.map { part, logs in
            SpendingBreakdown(id: part.rawValue, title: part.rawValue, amount: total(for: logs))
        }
        .sorted { $0.amount > $1.amount }
    }

    private static func dateRange(for period: SpendingPeriod, now: Date, calendar: Calendar) -> ClosedRange<Date>? {
        let today = calendar.startOfDay(for: now)
        switch period {
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: today)
            guard let start = calendar.date(from: comps) else { return nil }
            return start...today
        case .yearToDate:
            let year = calendar.component(.year, from: today)
            guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return nil }
            return start...today
        case .rollingYear:
            guard let start = calendar.date(byAdding: .year, value: -1, to: today) else { return nil }
            return start...today
        case .all:
            return nil
        }
    }
}
