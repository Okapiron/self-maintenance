import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceItem.createdAt) private var items: [MaintenanceItem]
    @AppStorage(SettingsKey.notificationHour) private var notificationHour = 9
    @AppStorage(SettingsKey.notificationMinute) private var notificationMinute = 0

    let theme: AppTheme
    @State private var showingAdd = false

    private var visibleItems: [MaintenanceItem] {
        items
            .filter { !$0.isHidden }
            .sorted {
                let left = MaintenanceStatusService.sortKey(for: $0)
                let right = MaintenanceStatusService.sortKey(for: $1)
                if left.0 != right.0 { return left.0 < right.0 }
                if left.1 != right.1 { return left.1 < right.1 }
                return left.2 < right.2
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    summary

                    if visibleItems.isEmpty {
                        ContentUnavailableView("項目がありません", systemImage: "plus.circle", description: Text("美容院や歯科など、管理したい項目を追加しましょう。"))
                            .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibleItems) { item in
                                NavigationLink {
                                    ItemDetailView(item: item, theme: theme)
                                } label: {
                                    MaintenanceCard(item: item, theme: theme) {
                                        item.deferUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                                        item.updatedAt = Date()
                                        NotificationService.cancel(item: item)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.softBackground.ignoresSafeArea())
            .navigationTitle("自己メンテ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                ItemFormView(theme: theme)
            }
        }
    }

    private var summary: some View {
        let visible = visibleItems
        let overdue = visible.filter { MaintenanceStatusService.statusInfo(for: $0).status == .overdue }.count
        let soon = visible.filter {
            let status = MaintenanceStatusService.statusInfo(for: $0).status
            return status == .soon || status == .nearDue
        }.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("次のメンテナンス")
                .font(.title2.weight(.bold))

            HStack(spacing: 10) {
                summaryPill(title: "そろそろ", value: soon)
                summaryPill(title: "期限超過", value: overdue)
                Spacer()
            }
        }
    }

    private func summaryPill(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)件")
                .font(.headline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}
