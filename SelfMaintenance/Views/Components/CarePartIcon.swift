import SwiftUI

struct CarePartIcon: View {
    let part: CarePart
    let theme: AppTheme
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.accent.opacity(0.10))

            Image(systemName: part.symbolName)
                .font(.system(size: size * 0.56, weight: .regular))
                .foregroundStyle(theme.accent)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
