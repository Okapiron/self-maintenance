import SwiftUI

struct HumanSpendingMapView: View {
    let breakdown: [SpendingBreakdown]
    @Binding var selectedPart: CarePart?
    let theme: AppTheme

    private let partOrder: [CarePart] = [.hair, .eyeArea, .eyes, .teeth, .hands, .faceBody, .body, .other]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("どこに使ったか")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                HStack(alignment: .top, spacing: 16) {
                    bodyMap
                        .frame(width: 128, height: 256)
                        .padding(.top, 12)

                    VStack(spacing: 6) {
                        ForEach(partOrder) { part in
                            labelRow(part)
                        }
                    }
                    .padding(.top, 10)

                    Spacer(minLength: 0)
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 294)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var bodyMap: some View {
        ZStack {
            Image("HumanFigure")
                .resizable()
                .scaledToFit()
                .opacity(0.72)
                .frame(width: 128, height: 256)

            ForEach(partOrder) { part in
                partDot(part)
            }
        }
    }

    private func partDot(_ part: CarePart) -> some View {
        let isSelected = selectedPart == part
        return ZStack {
            if isSelected {
                Circle()
                    .fill(theme.accent.opacity(0.18))
                    .frame(width: 28, height: 28)
            }
            Circle()
                .fill(isSelected ? theme.accent : theme.accent.opacity(0.48))
                .frame(width: isSelected ? 18 : 8, height: isSelected ? 18 : 8)
                .overlay(
                    Circle()
                        .stroke(.background, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(color: isSelected ? theme.accent.opacity(0.35) : .clear, radius: 5, y: 2)
        }
            .position(dotPosition(for: part))
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: selectedPart)
    }

    private func labelRow(_ part: CarePart) -> some View {
        let amount = breakdown.first(where: { $0.title == part.rawValue })?.amount ?? 0
        let isSelected = selectedPart == part

        return Button {
            selectedPart = part
        } label: {
            HStack(spacing: 8) {
                Image(systemName: part.symbolName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(theme.accent)
                    .frame(width: 22)

                Text(part.rawValue)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(currency(amount))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(amount == 0 ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(isSelected ? theme.accent.opacity(0.14) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 1.5)
            )
            .opacity(amount == 0 ? 0.62 : 1)
        }
        .buttonStyle(.plain)
    }

    private func dotPosition(for part: CarePart) -> CGPoint {
        switch part {
        case .hair:
            CGPoint(x: 64, y: 26)
        case .eyeArea:
            CGPoint(x: 78, y: 72)
        case .eyes:
            CGPoint(x: 84, y: 72)
        case .teeth:
            CGPoint(x: 64, y: 94)
        case .hands:
            CGPoint(x: 106, y: 170)
        case .faceBody:
            CGPoint(x: 82, y: 122)
        case .body:
            CGPoint(x: 64, y: 150)
        case .other:
            CGPoint(x: 64, y: 224)
        }
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
