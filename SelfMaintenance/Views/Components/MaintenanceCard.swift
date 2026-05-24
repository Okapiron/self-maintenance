import SwiftUI

struct MaintenanceCard: View {
    let item: MaintenanceItem
    let theme: AppTheme
    let onDefer: () -> Void

    private var statusInfo: MaintenanceStatusInfo {
        MaintenanceStatusService.statusInfo(for: item)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                CarePartIcon(part: item.carePart, theme: theme, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                    Text(item.carePart.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
            }

            StatusBadge(status: statusInfo.status, text: statusInfo.displayText, theme: theme)

            HStack(alignment: .bottom, spacing: 10) {
                HStack(spacing: 18) {
                    meta(title: "前回", value: item.latestLog.map { Self.dateFormatter.string(from: $0.performedAt) } ?? "-")
                    meta(title: "次回目安", value: statusInfo.dueDate.map { Self.dateFormatter.string(from: $0) } ?? "-")
                    if let amount = item.latestLog?.amount {
                        meta(title: "直近", value: Self.currencyFormatter.string(from: NSNumber(value: amount)) ?? "¥\(amount)")
                    }
                }
                Spacer(minLength: 4)
                NavigationLink {
                    LogFormView(item: item, theme: theme)
                } label: {
                    Label("記録する", systemImage: "square.and.pencil")
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 116, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .controlSize(.small)
            }

            if statusInfo.status == .overdue || statusInfo.status == .nearDue {
                HStack {
                    Spacer(minLength: 0)
                    Button("あとで確認") {
                        onDefer()
                    }
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(theme.accent)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func meta(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
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
