import SwiftUI

struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @State private var currentPage = 0

    private let pages: [(emoji: String, title: String, subtitle: String, description: String)] = [
        (
            "\u{1F98A}",
            "Welcome to Progression",
            "Your journey begins here",
            "Build streaks, hit Fibonacci milestones, and grow your habits one step at a time!"
        ),
        (
            "\u{1F525}",
            "Streaks are Fibonacci Milestones",
            "1, 2, 3, 5, 8, 13, 21...",
            "Streaks and Fibonacci milestones celebrate your consistency and set a zen-like rhythm."
        ),
        (
            "\u{2B50}",
            "Create your first activity!",
            "Start with a free one",
            "Create your first free activity, set a simple goal, and watch your streak grow!"
        ),
    ]

    var body: some View {
        ZStack {
            // Warm cream background
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            authService.completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                    }
                }
                .frame(height: 44)

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        onboardingPage(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Theme.Colors.primary : Theme.Colors.cardBorder)
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(Theme.Animation.quick, value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Bottom button
                Button {
                    if currentPage == 0 {
                        // "Sign In" on first page per design
                        withAnimation { currentPage += 1 }
                    } else if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        authService.completeOnboarding()
                    }
                } label: {
                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Theme.Colors.primary, Theme.Colors.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.buttonRadius))
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Sign In"
        case pages.count - 1: return "Get Started"
        default: return "Next"
        }
    }

    @ViewBuilder
    private func onboardingPage(index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Page-specific illustration
            pageIllustration(for: index)

            VStack(spacing: 12) {
                Text(pages[index].title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(pages[index].subtitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primary)

                Text(pages[index].description)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(3)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func pageIllustration(for index: Int) -> some View {
        switch index {
        case 0:
            // Fox mascot with Fibonacci ring demo
            VStack(spacing: 16) {
                Text("\u{1F98A}")
                    .font(.system(size: 80))

                FibonacciRingDemo()
            }

        case 1:
            // Flame with streak visualization
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.15),
                                    Theme.Colors.accent.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)

                    Text("\u{1F525}")
                        .font(.system(size: 64))
                }

                // Fibonacci number sequence
                HStack(spacing: 6) {
                    ForEach([1, 2, 3, 5, 8, 13, 21], id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.foxCream)
                            .clipShape(Capsule())
                    }
                }
            }

        default:
            // Star with "1 FREE POINT" badge
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.accent.opacity(0.2),
                                    Theme.Colors.primary.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)

                    Text("\u{2B50}")
                        .font(.system(size: 64))
                }

                // "1 FREE POINT" badge
                Text("1 FREE POINT")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 6, y: 3)
            }
        }
    }
}

// Animated ring demo for onboarding
private struct FibonacciRingDemo: View {
    @State private var demoStreak = 0

    var body: some View {
        VStack(spacing: 12) {
            FibonacciRingView(
                streak: demoStreak,
                color: Theme.Colors.primary,
                isCompleted: false,
                size: 120
            )

            HStack(spacing: 4) {
                ForEach([1, 2, 3, 5, 8], id: \.self) { fib in
                    Text("\(fib)")
                        .font(.system(size: 12, weight: demoStreak >= fib ? .bold : .regular, design: .rounded))
                        .foregroundStyle(demoStreak >= fib ? Theme.Colors.primary : Theme.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            demoStreak >= fib ? Theme.Colors.accent.opacity(0.15) : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear {
            animateDemo()
        }
    }

    private func animateDemo() {
        let sequence = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        for (i, val) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(Theme.Animation.spring) {
                    demoStreak = val
                }
            }
        }
        // Loop
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(sequence.count) * 0.5 + 1.0) {
            withAnimation { demoStreak = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateDemo()
            }
        }
    }
}

