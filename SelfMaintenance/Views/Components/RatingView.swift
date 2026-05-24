import SwiftUI

struct RatingView: View {
    @Binding var rating: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = rating == value ? nil : value
                } label: {
                    Image(systemName: (rating ?? 0) >= value ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle((rating ?? 0) >= value ? Color.yellow : Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("満足度")
    }
}
