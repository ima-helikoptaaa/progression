import SwiftUI

struct FibonacciRingView: View {
    let streak: Int
    let color: Color
    let isCompleted: Bool
    var size: CGFloat = 80
    var showTickMarks: Bool = true

    private var progress: Double {
        FibonacciHelper.progress(for: streak)
    }

    private var lineWidth: CGFloat {
        size > 100 ? 10 : 6
    }

    private var isNearMilestone: Bool {
        let next = FibonacciHelper.nextFibonacci(streak)
        return (next - streak) <= 2 && streak > 0
    }

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Warm orange glow effect when near milestone
            if isNearMilestone {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.2),
                                Theme.Colors.accent.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.3,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size + 16, height: size + 16)
                    .blur(radius: 8)
                    .opacity(glowOpacity)
            }

            // Background track - warm cream/orange tint
            Circle()
                .stroke(Theme.Colors.cardBorder, lineWidth: lineWidth)

            // Tick marks at Fibonacci positions - orange-tinted
            if showTickMarks && size >= 60 {
                ForEach(FibonacciHelper.checkpoints.prefix(8), id: \.self) { checkpoint in
                    let tickProgress = FibonacciHelper.progress(for: checkpoint)
                    let angle = Angle.degrees(360 * tickProgress - 90)
                    Circle()
                        .fill(streak >= checkpoint ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.25))
                        .frame(width: size > 100 ? 5 : 3, height: size > 100 ? 5 : 3)
                        .offset(y: -(size / 2))
                        .rotationEffect(angle)
                }
            }

            // Progress arc with warm orange gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.accent.opacity(0.6),
                            Theme.Colors.primaryLight,
                            Theme.Colors.primary
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.spring, value: progress)

            // Center content
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(Theme.Colors.success)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("\(streak)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(pulseScale)
        .onAppear {
            if isCompleted {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.03
                }
            }
            if isNearMilestone {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.6
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        FibonacciRingView(streak: 5, color: .purple, isCompleted: false, size: 80)
        FibonacciRingView(streak: 8, color: .teal, isCompleted: true, size: 80)
        FibonacciRingView(streak: 12, color: .green, isCompleted: false, size: 120)
    }
    .padding()
    .background(Theme.Colors.background)
}
