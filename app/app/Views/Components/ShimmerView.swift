import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
            .fill(Theme.Colors.cardBorder.opacity(0.5))
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Theme.Colors.textPrimary.opacity(0),
                            Theme.Colors.textPrimary.opacity(0.06),
                            Theme.Colors.textPrimary.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width * 1.6 - geo.size.width * 0.3)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct ShimmerCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ShimmerView()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerView()
                        .frame(width: 120, height: 14)
                    ShimmerView()
                        .frame(width: 80, height: 10)
                }
                Spacer()
            }
            ShimmerView()
                .frame(height: 60)
            ShimmerView()
                .frame(height: 36)
        }
        .padding(Theme.Layout.cardPadding)
        .appleCard()
    }
}
