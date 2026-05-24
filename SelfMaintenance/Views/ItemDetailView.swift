import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.notificationHour) private var notificationHour = 9
    @AppStorage(SettingsKey.notificationMinute) private var notificationMinute = 0

    @Bindable var item: MaintenanceItem
    let theme: AppTheme

    @State private var showingLogForm = false
    @State private var editingLog: MaintenanceLog?
    @State private var showingItemEdit = false
    @State private var showingDueDateEdit = false
    @State private var editedDueDate = Date()
    @State private var showingDeleteAlert = false

    private var statusInfo: MaintenanceStatusInfo {
        MaintenanceStatusService.statusInfo(for: item)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                quickActions
                details
                history
            }
            .padding(16)
        }
        .background(theme.softBackground.ignoresSafeArea())
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("編集") {
                        showingItemEdit = true
                    }
                    Button("非表示にする") {
                        hideItem()
                    }
                    Button("完全に削除", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingLogForm) {
            LogFormView(item: item, theme: theme)
        }
        .sheet(item: $editingLog) { log in
            LogFormView(log: log, theme: theme)
        }
        .sheet(isPresented: $showingItemEdit) {
            ItemFormView(mode: .edit(item), theme: theme)
        }
        .sheet(isPresented: $showingDueDateEdit) {
            dueDateEditSheet
        }
        .alert("完全に削除しますか？", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                NotificationService.cancel(item: item)
                modelContext.delete(item)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この項目とすべての履歴が削除されます。元に戻せません。")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                CarePartIcon(part: item.carePart, theme: theme, size: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(item.carePart.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            StatusBadge(status: statusInfo.status, text: statusInfo.displayText, theme: theme)

            HStack(alignment: .bottom, spacing: 16) {
                infoTile(title: "前回", value: item.latestLog.map { Self.dateFormatter.string(from: $0.performedAt) } ?? "-")
                infoTile(title: "次回目安", value: statusInfo.dueDate.map { Self.dateFormatter.string(from: $0) } ?? "-")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                primaryAction(title: "記録する", systemImage: "square.and.pencil") {
                    showingLogForm = true
                }
                secondaryAction(title: "目安日変更", systemImage: "calendar.badge.clock") {
                    editedDueDate = statusInfo.dueDate ?? Date()
                    showingDueDateEdit = true
                }
            }
            if statusInfo.status == .overdue || statusInfo.status == .nearDue {
                HStack {
                    secondaryAction(title: "あとで確認", systemImage: "clock") {
                        item.deferUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                        item.updatedAt = Date()
                        NotificationService.cancel(item: item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("設定")
                .font(.headline)

            VStack(spacing: 10) {
                row(title: "周期", value: "\(item.intervalValue)\(item.intervalUnit.rawValue)")
                row(title: "通知", value: item.notificationEnabled ? item.notificationTiming.rawValue : "通知しない")
                if !item.memo.isEmpty {
                    row(title: "メモ", value: item.memo)
                }
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("履歴")
                .font(.headline)

            if item.visibleLogs.isEmpty {
                ContentUnavailableView("まだ記録がありません", systemImage: "clock.badge.questionmark")
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(item.visibleLogs) { log in
                        Button {
                            editingLog = log
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Self.dateFormatter.string(from: log.performedAt))
                                        .font(.subheadline.weight(.semibold))
                                    if !log.shopName.isEmpty {
                                        Text(log.shopName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let amount = log.amount {
                                    Text(Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "¥\(amount)")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .padding(14)
                            .background(.background, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dueDateEditSheet: some View {
        NavigationStack {
            Form {
                Section("次回目安日") {
                    DatePicker("日付", selection: $editedDueDate, displayedComponents: .date)
                }
                Section {
                    Button("自動計算に戻す") {
                        item.customNextDueDate = nil
                        item.deferUntil = nil
                        item.updatedAt = Date()
                        Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
                        showingDueDateEdit = false
                    }
                }
            }
            .navigationTitle("目安日を変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        showingDueDateEdit = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        item.customNextDueDate = editedDueDate
                        item.deferUntil = nil
                        item.updatedAt = Date()
                        Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
                        showingDueDateEdit = false
                    }
                }
            }
        }
    }

    private func hideItem() {
        item.isHidden = true
        item.updatedAt = Date()
        NotificationService.cancel(item: item)
        dismiss()
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func primaryAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(theme.accent, in: Capsule())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func secondaryAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(.background, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accent)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d"
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
