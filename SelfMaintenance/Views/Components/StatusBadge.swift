import SwiftUI

struct StatusBadge: View {
    let status: MaintenanceStatus
    let text: String
    let theme: AppTheme

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .unrecorded: .secondary
        case .plenty: Color(red: 0.18, green: 0.55, blue: 0.34)
        case .soon: Color(red: 0.86, green: 0.54, blue: 0.12)
        case .nearDue: theme.accent
        case .overdue: Color(red: 0.82, green: 0.24, blue: 0.22)
        case .deferred: Color(red: 0.46, green: 0.43, blue: 0.39)
        }
    }
}
