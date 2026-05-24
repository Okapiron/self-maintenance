import SwiftData
import SwiftUI

struct ItemFormView: View {
    enum Mode {
        case create
        case edit(MaintenanceItem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceItem.createdAt) private var items: [MaintenanceItem]
    @AppStorage(SettingsKey.notificationHour) private var notificationHour = 9
    @AppStorage(SettingsKey.notificationMinute) private var notificationMinute = 0

    let mode: Mode
    let theme: AppTheme

    @State private var selectedPreset: MaintenancePreset?
    @State private var showingForm = false
    @State private var name = ""
    @State private var carePart: CarePart = .other
    @State private var intervalValue = 1
    @State private var intervalUnit: IntervalUnit = .month
    @State private var notificationEnabled = true
    @State private var notificationTiming: NotificationTiming = .soonStart
    @State private var hasInitialLog = false
    @State private var initialLogDate = Date()
    @State private var memo = ""
    @State private var duplicateItem: MaintenanceItem?
    @State private var duplicateIsHidden = false
    @State private var showingDuplicateAlert = false

    init(mode: Mode = .create, theme: AppTheme) {
        self.mode = mode
        self.theme = theme
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .create where !showingForm:
                    presetPicker
                default:
                    form
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
                if showingForm || isEditing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            save()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear(perform: loadEditValues)
            .alert(duplicateIsHidden ? "非表示にした項目があります" : "すでに追加されています", isPresented: $showingDuplicateAlert) {
                if duplicateIsHidden {
                    Button("再表示する") {
                        duplicateItem?.isHidden = false
                        duplicateItem?.updatedAt = Date()
                        if let duplicateItem {
                            Task { await NotificationService.schedule(item: duplicateItem, hour: notificationHour, minute: notificationMinute) }
                        }
                        dismiss()
                    }
                } else {
                    Button("既存の項目を開く") {
                        dismiss()
                    }
                }
                Button("別名で作成") {
                    name = "\(name) 2"
                    showingForm = true
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            showingForm ? "項目を追加" : "項目を追加"
        case .edit:
            "項目を編集"
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var presetPicker: some View {
        List {
            Section("よく使うメンテナンス") {
                ForEach(PresetService.presets) { preset in
                    Button {
                        select(preset)
                    } label: {
                        HStack {
                            CarePartIcon(part: preset.carePart, theme: theme, size: 32)
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                Text("\(preset.carePart.rawValue)・\(preset.intervalValue)\(preset.intervalUnit.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    selectedPreset = nil
                    name = ""
                    carePart = .other
                    intervalValue = 1
                    intervalUnit = .month
                    showingForm = true
                } label: {
                    Label("自由に作成", systemImage: "plus.circle")
                }
            }
        }
    }

    private var form: some View {
        Form {
            Section("基本") {
                TextField("項目名", text: $name)

                Picker("ケア部位", selection: $carePart) {
                    ForEach(CarePart.allCases) { part in
                        Text(part.rawValue).tag(part)
                    }
                }

                HStack {
                    Picker("数字", selection: $intervalValue) {
                        ForEach(1...36, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Picker("単位", selection: $intervalUnit) {
                        ForEach(IntervalUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 130)
            }

            Section("通知") {
                Toggle("通知", isOn: $notificationEnabled)
                if notificationEnabled {
                    Picker("タイミング", selection: $notificationTiming) {
                        ForEach(NotificationTiming.allCases) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                }
            }

            if !isEditing {
                Section("前回実施日") {
                    Toggle("前回日を入力する", isOn: $hasInitialLog)
                    if hasInitialLog {
                        DatePicker("実施日", selection: $initialLogDate, in: ...Date(), displayedComponents: .date)
                    }
                }
            }

            Section("メモ") {
                TextField("メモ", text: $memo, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    private func select(_ preset: MaintenancePreset) {
        selectedPreset = preset
        name = preset.name
        carePart = preset.carePart
        intervalValue = preset.intervalValue
        intervalUnit = preset.intervalUnit

        if let existing = items.first(where: { $0.presetKey == preset.id || $0.name == preset.name }) {
            duplicateItem = existing
            duplicateIsHidden = existing.isHidden
            showingDuplicateAlert = true
        } else {
            showingForm = true
        }
    }

    private func loadEditValues() {
        guard case let .edit(item) = mode else { return }
        name = item.name
        carePart = item.carePart
        intervalValue = item.intervalValue
        intervalUnit = item.intervalUnit
        notificationEnabled = item.notificationEnabled
        notificationTiming = item.notificationTiming
        memo = item.memo
    }

    private func save() {
        switch mode {
        case .create:
            let item = MaintenanceItem(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                presetKey: selectedPreset?.id,
                carePart: carePart,
                intervalValue: intervalValue,
                intervalUnit: intervalUnit,
                notificationEnabled: notificationEnabled,
                notificationTiming: notificationTiming,
                memo: memo
            )
            modelContext.insert(item)
            if hasInitialLog {
                let log = MaintenanceLog(performedAt: initialLogDate, item: item)
                modelContext.insert(log)
                item.logs.append(log)
            }
            Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
        case let .edit(item):
            item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            item.carePart = carePart
            item.intervalValue = intervalValue
            item.intervalUnit = intervalUnit
            item.notificationEnabled = notificationEnabled
            item.notificationTiming = notificationTiming
            item.memo = memo
            item.updatedAt = Date()
            Task { await NotificationService.schedule(item: item, hour: notificationHour, minute: notificationMinute) }
        }
        dismiss()
    }
}
