import SwiftData
import SwiftUI

struct LogFormView: View {
    enum Mode {
        case create(MaintenanceItem)
        case edit(MaintenanceLog)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.notificationHour) private var notificationHour = 9
    @AppStorage(SettingsKey.notificationMinute) private var notificationMinute = 0

    let mode: Mode
    let theme: AppTheme

    @State private var performedAt = Date()
    @State private var amountText = ""
    @State private var shopName = ""
    @State private var staffName = ""
    @State private var satisfaction: Int?
    @State private var memo = ""

    init(item: MaintenanceItem, theme: AppTheme) {
        self.mode = .create(item)
        self.theme = theme
    }

    init(log: MaintenanceLog, theme: AppTheme) {
        self.mode = .edit(log)
        self.theme = theme
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("実施日") {
                    DatePicker("実施日", selection: $performedAt, in: ...Date(), displayedComponents: .date)
                }

                Section("内容") {
                    TextField("金額", text: $amountText)
                        .keyboardType(.numberPad)
                    TextField("店舗名", text: $shopName)
                    TextField("担当者", text: $staffName)
                    RatingView(rating: $satisfaction)
                }

                Section("メモ") {
                    TextField("メモ", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if case .edit = mode {
                    Section {
                        Button("この記録を削除", role: .destructive) {
                            deleteLog()
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                }
            }
            .onAppear(perform: loadValues)
        }
    }

    private func loadValues() {
        guard case let .edit(log) = mode else { return }
        performedAt = log.performedAt
        amountText = log.amount.map(String.init) ?? ""
        shopName = log.shopName
        staffName = log.staffName
        satisfaction = log.satisfaction
        memo = log.memo
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            "記録を追加"
        case .edit:
            "記録を編集"
        }
    }

    private func save() {
        let amount = Int(amountText.trimmingCharacters(in: .whitespacesAndNewlines))

        switch mode {
        case let .create(item):
            let log = MaintenanceLog(
                performedAt: performedAt,
                amount: amount,
                shopName: shopName,
                staffName: staffName,
                satisfaction: satisfaction,
                memo: memo,
                item: item
            )
            modelContext.insert(log)
            item.logs.append(log)
            item.customNextDueDate = nil
            item.deferUntil = nil
            item.updatedAt = Date()
            Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
        case let .edit(log):
            log.performedAt = performedAt
            log.amount = amount
            log.shopName = shopName
            log.staffName = staffName
            log.satisfaction = satisfaction
            log.memo = memo
            log.updatedAt = Date()
            log.item?.updatedAt = Date()
            if let item = log.item {
                Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
            }
        }
        dismiss()
    }

    private func deleteLog() {
        guard case let .edit(log) = mode else { return }
        let item = log.item
        item?.logs.removeAll { $0.id == log.id }
        modelContext.delete(log)
        item?.updatedAt = Date()
        if let item {
            Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
        }
        dismiss()
    }
}
