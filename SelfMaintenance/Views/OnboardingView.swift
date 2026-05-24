import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    let theme: AppTheme
    @State private var selectedPresetIDs: Set<String> = ["hair_salon", "dentist", "eyebrow_salon"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("自己メンテナンスの\n「そろそろ」を忘れない")
                            .font(.system(size: 30, weight: .bold))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("前回の日付と次回の目安を、手帳のようにまとめて管理できます。")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("まず使う項目を選択")
                            .font(.headline)

                        VStack(spacing: 10) {
                            ForEach(PresetService.presets) { preset in
                                Button {
                                    toggle(preset.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        CarePartIcon(part: preset.carePart, theme: theme, size: 34)

                                        Text(preset.name)
                                            .font(.subheadline.weight(.semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)

                                        Spacer()

                                        Text("\(preset.intervalValue)\(preset.intervalUnit.rawValue)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)

                                        Image(systemName: selectedPresetIDs.contains(preset.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(selectedPresetIDs.contains(preset.id) ? theme.accent : .secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 58)
                                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedPresetIDs.contains(preset.id) ? theme.accent : Color(.separator), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        createSelectedItems()
                        hasCompletedOnboarding = true
                    } label: {
                        Text("はじめる")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                    .disabled(selectedPresetIDs.isEmpty)
                }
                .padding(20)
            }
            .background(theme.softBackground.ignoresSafeArea())
        }
    }

    private func toggle(_ id: String) {
        if selectedPresetIDs.contains(id) {
            selectedPresetIDs.remove(id)
        } else {
            selectedPresetIDs.insert(id)
        }
    }

    private func createSelectedItems() {
        for preset in PresetService.presets where selectedPresetIDs.contains(preset.id) {
            let item = MaintenanceItem(
                name: preset.name,
                presetKey: preset.id,
                carePart: preset.carePart,
                intervalValue: preset.intervalValue,
                intervalUnit: preset.intervalUnit
            )
            modelContext.insert(item)
        }
    }
}
