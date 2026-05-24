import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceItem.createdAt) private var items: [MaintenanceItem]
    @AppStorage(SettingsKey.selectedTheme) private var selectedTheme = AppTheme.cleanBlue.rawValue
    @AppStorage(SettingsKey.notificationHour) private var notificationHour = 9
    @AppStorage(SettingsKey.notificationMinute) private var notificationMinute = 0
    @AppStorage(SettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = true

    let theme: AppTheme
    @State private var notificationStatus = "確認中"
    @State private var showingDeleteAllAlert = false

    private var hiddenItems: [MaintenanceItem] {
        items.filter(\.isHidden)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("テーマ") {
                    Picker("テーマ", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }
                }

                Section("通知") {
                    DatePicker(
                        "通知時刻",
                        selection: notificationTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    LabeledContent("通知許可", value: notificationStatus)
                    Button("通知を許可する") {
                        Task {
                            _ = await NotificationService.requestAuthorizationIfNeeded()
                            await refreshNotificationStatus()
                        }
                    }
                }

                Section("非表示の項目") {
                    if hiddenItems.isEmpty {
                        Text("非表示の項目はありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(hiddenItems) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Button("再表示") {
                                    item.isHidden = false
                                    item.updatedAt = Date()
                                    Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                Section("データ管理") {
                    Button("全データを削除", role: .destructive) {
                        showingDeleteAllAlert = true
                    }
                }

                Section("サポート") {
                    Link("プライバシーポリシー", destination: Self.privacyPolicyURL)
                    Link("お問い合わせ", destination: Self.supportURL)
                    LabeledContent("アプリ", value: "自己メンテナンス")
                    LabeledContent("バージョン", value: appVersion)
                }
            }
            .navigationTitle("設定")
            .task {
                await refreshNotificationStatus()
            }
            .alert("全データを削除しますか？", isPresented: $showingDeleteAllAlert) {
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("項目と履歴がすべて削除されます。テーマなどの設定は残ります。")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    private static let privacyPolicyURL = URL(string: "https://okapiron.github.io/self-maintenance/privacy.html")!
    private static let supportURL = URL(string: "https://okapiron.github.io/self-maintenance/support.html")!

    private var notificationTimeBinding: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: notificationHour, minute: notificationMinute)) ?? Date()
        } set: { newValue in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            notificationHour = comps.hour ?? 9
            notificationMinute = comps.minute ?? 0
            for item in items where !item.isHidden {
                Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
            }
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: "許可済み"
            case .denied: "拒否"
            case .notDetermined: "未設定"
            @unknown default: "不明"
            }
        }
    }

    private func deleteAllData() {
        NotificationService.cancelAll()
        for item in items {
            modelContext.delete(item)
        }
        hasCompletedOnboarding = false
    }
}
