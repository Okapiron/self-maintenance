import SwiftData
import SwiftUI

struct SpendingView: View {
    @Query(sort: \MaintenanceItem.createdAt) private var items: [MaintenanceItem]

    let theme: AppTheme
    @State private var selectedPeriod: SpendingPeriod = .month
    @State private var selectedPart: CarePart?

    private var periodLogs: [MaintenanceLog] {
        SpendingSummaryService.logs(in: selectedPeriod, from: items)
    }

    private var total: Int {
        SpendingSummaryService.total(for: periodLogs)
    }

    private var partBreakdown: [SpendingBreakdown] {
        SpendingSummaryService.byCarePart(for: periodLogs)
    }

    private var itemBreakdown: [SpendingBreakdown] {
        SpendingSummaryService.byItem(for: items, logs: periodLogs)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(SpendingPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    totalCard

                    HumanSpendingMapView(
                        breakdown: partBreakdown,
                        selectedPart: $selectedPart,
                        theme: theme
                    )

                    selectedPartList
                    rankingList
                }
                .padding(16)
            }
            .background(theme.softBackground.ignoresSafeArea())
            .navigationTitle("支出")
        }
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(selectedPeriod.rawValue)の合計")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(currency(total))
                .font(.system(size: 34, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var selectedPartList: some View {
        let part = selectedPart ?? CarePart(rawValue: partBreakdown.first?.title ?? "") ?? .hair
        let logs = periodLogs.filter { $0.item?.carePart == part && $0.amount != nil }
        let grouped = Dictionary(grouping: logs) { $0.item?.name ?? "未設定" }
            .map { SpendingBreakdown(id: $0.key, title: $0.key, amount: SpendingSummaryService.total(for: $0.value)) }
            .sorted { $0.amount > $1.amount }

        return VStack(alignment: .leading, spacing: 10) {
            Text("選択部位の内訳")
                .font(.headline)
            if grouped.isEmpty {
                Text("金額を入力すると支出を確認できます")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(grouped) { row in
                    spendingRow(row)
                }
            }
        }
    }

    private var rankingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("項目別ランキング")
                .font(.headline)
            if itemBreakdown.isEmpty {
                Text("金額を入力すると支出を確認できます")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(itemBreakdown) { row in
                    spendingRow(row)
                }
            }
        }
    }

    private func spendingRow(_ row: SpendingBreakdown) -> some View {
        HStack {
            Text(row.title)
            Spacer()
            Text(currency(row.amount))
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func currency(_ value: Int) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "¥\(value)"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
