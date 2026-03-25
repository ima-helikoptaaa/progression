import SwiftUI

struct CelebrationOverlay: View {
    @Binding var isPresented: Bool
    let streak: Int

    @State private var showContent = false
    @State private var particles: [ConfettiParticle] = []

    private var celebrationMessage: (title: String, emoji: String) {
        switch streak {
        case 1: return ("First paw print! \u{1F98A}", "\u{1F98A}")
        case 2: return ("Fox on fire! \u{1F525}", "\u{1F525}")
        case 3: return ("Sly and steady! \u{1F98A}", "\u{1F98A}")
        case 5: return ("Five-day fox trot! \u{26A1}", "\u{26A1}")
        case 8: return ("Fibonacci Fox! \u{1F3AF}", "\u{1F98A}")
        case 13: return ("Unstoppable fox! \u{1F680}", "\u{1F98A}")
        case 21: return ("Legendary fox spirit! \u{1F31F}", "\u{1F98A}")
        case 34: return ("Alpha fox! \u{1F451}", "\u{1F98A}")
        case 55...: return ("Mythic fox! \u{1F48E}", "\u{1F98A}")
        default: return ("Fox milestone! \u{1F389}", "\u{1F98A}")
        }
    }

    var body: some View {
        if isPresented {
            ZStack {
                // Dark overlay with warm orange glow
                ZStack {
                    Color.black.opacity(0.6)
                    RadialGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.3),
                            Theme.Colors.accent.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 300
                    )
                }
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

                // Confetti particles
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        for particle in particles {
                            let age = elapsed - particle.startTime
                            guard age >= 0, age < particle.lifetime else { continue }

                            let progress = age / particle.lifetime
                            let gravity = 120.0 * age * age
                            let wind = particle.windForce * age

                            let x = particle.startX * size.width + wind
                            let y = particle.startY * size.height + gravity - 200 * (1 - progress)

                            let rotation = Angle.degrees(particle.rotationSpeed * age)
                            let opacity = 1.0 - max(0, progress - 0.6) / 0.4

                            guard y < size.height + 20 else { continue }

                            context.opacity = opacity
                            context.translateBy(x: x, y: y)
                            context.rotate(by: rotation)

                            switch particle.shape {
                            case 0:
                                let rect = CGRect(x: -4, y: -4, width: 8, height: 8)
                                context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                            case 1:
                                let rect = CGRect(x: -3, y: -5, width: 6, height: 10)
                                context.fill(Path(rect), with: .color(particle.color))
                            default:
                                var path = Path()
                                path.move(to: CGPoint(x: 0, y: -6))
                                path.addLine(to: CGPoint(x: 5, y: 4))
                                path.addLine(to: CGPoint(x: -5, y: 4))
                                path.closeSubpath()
                                context.fill(path, with: .color(particle.color))
                            }

                            context.rotate(by: -rotation)
                            context.translateBy(x: -x, y: -y)
                        }
                    }
                }
                .ignoresSafeArea()

                // Center celebration content
                VStack(spacing: 20) {
                    // Fox mascot
                    Text("\u{1F98A}")
                        .font(.system(size: 72))
                        .shadow(color: Theme.Colors.primary.opacity(0.6), radius: 20)

                    Text("\(streak) DAY STREAK!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Theme.Colors.primary.opacity(0.8), radius: 12)

                    Text(celebrationMessage.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    // +1 Point Earned badge
                    HStack(spacing: 6) {
                        Image(systemName: Theme.Icons.pointIcon)
                            .font(.system(size: 14, weight: .bold))
                        Text("+1 Point Earned")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Theme.Colors.primary.opacity(0.5), radius: 8, y: 4)
                    )
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)
            }
            .onAppear {
                generateParticles()
                HapticManager.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    HapticManager.success()
                }
                withAnimation(Theme.Animation.spring) {
                    showContent = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            particles = []
        }
    }

    private func generateParticles() {
        // Warm confetti tones: orange, amber, gold, coral, white
        let colors: [Color] = [
            Theme.Colors.primary,       // warm orange
            Theme.Colors.primaryLight,   // lighter orange
            Theme.Colors.accent,         // golden amber
            Color(hex: "FF7F50"),         // coral
            Color(hex: "FFD700"),         // gold
            .white
        ]
        let now = Date().timeIntervalSinceReferenceDate

        particles = (0..<80).map { _ in
            ConfettiParticle(
                startX: Double.random(in: 0.05...0.95),
                startY: Double.random(in: -0.3...0.1),
                startTime: now + Double.random(in: 0...0.5),
                lifetime: Double.random(in: 2.5...4.0),
                windForce: Double.random(in: -30...30),
                rotationSpeed: Double.random(in: -360...360),
                color: colors.randomElement()!,
                shape: Int.random(in: 0...2)
            )
        }
    }
}

private struct ConfettiParticle {
    let startX: Double
    let startY: Double
    let startTime: Double
    let lifetime: Double
    let windForce: Double
    let rotationSpeed: Double
    let color: Color
    let shape: Int
}
