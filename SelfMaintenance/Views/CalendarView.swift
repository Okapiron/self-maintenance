import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: \MaintenanceItem.createdAt) private var items: [MaintenanceItem]

    let theme: AppTheme
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    weekdayHeader
                    calendarGrid
                    selectedList
                }
                .padding(16)
            }
            .background(theme.softBackground.ignoresSafeArea())
            .navigationTitle("カレンダー")
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()
            Text(Self.monthFormatter.string(from: displayedMonth))
                .font(.title3.weight(.bold))
            Spacer()

            Button {
                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(theme.accent)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(height: 24)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(monthDays, id: \.self) { date in
                dayCell(date)
            }
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var selectedList: some View {
        let events = events(on: selectedDate)
        return VStack(alignment: .leading, spacing: 12) {
            Text(Self.dateFormatter.string(from: selectedDate))
                .font(.headline)

            if events.isEmpty {
                Text("この日の記録や目安はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(events, id: \.id) { event in
                    NavigationLink {
                        ItemDetailView(item: event.item, theme: theme)
                    } label: {
                        HStack {
                            Circle()
                                .fill(event.kind == .log ? theme.accent : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(event.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .padding()
                        .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
        let events = events(on: date)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(isSelected ? theme.accent.opacity(0.18) : Color.clear, in: Circle())

                HStack(spacing: 4) {
                    if events.contains(where: { $0.kind == .log }) {
                        Circle().fill(theme.accent).frame(width: 8, height: 8)
                    }
                    if events.contains(where: { $0.kind == .due }) {
                        Circle().stroke(Color.orange, lineWidth: 2).frame(width: 8, height: 8)
                    }
                }
                .frame(height: 12)
            }
        }
        .buttonStyle(.plain)
    }

    private var monthDays: [Date] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        let weekday = calendar.component(.weekday, from: monthStart)
        let start = calendar.date(byAdding: .day, value: -(weekday - 1), to: monthStart) ?? monthStart
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func events(on date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        var result: [CalendarEvent] = []

        for item in items where !item.isHidden {
            for log in item.logs where calendar.isDate(log.performedAt, inSameDayAs: date) {
                result.append(CalendarEvent(item: item, title: logTitle(for: item), kind: .log))
            }

            if let due = MaintenanceStatusService.nextDueDate(for: item), calendar.isDate(due, inSameDayAs: date) {
                result.append(CalendarEvent(item: item, title: "\(item.name)の目安日です", kind: .due))
            }
        }

        return result
    }

    private func logTitle(for item: MaintenanceItem) -> String {
        item.name == "健康診断" ? "健康診断を受けた" : "\(item.name)に行った"
    }

    private struct CalendarEvent {
        enum Kind {
            case log
            case due
        }

        let id = UUID()
        let item: MaintenanceItem
        let title: String
        let kind: Kind
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}
