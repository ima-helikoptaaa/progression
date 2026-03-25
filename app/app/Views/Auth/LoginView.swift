import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var titleScale = 0.8
    @State private var titleOpacity = 0.0
    @State private var taglineText = ""
    @State private var foxBounce = false

    private let fullTagline = "Start small. Grow exponentially."

    var body: some View {
        ZStack {
            // Warm cream background
            Theme.Colors.background
                .ignoresSafeArea()

            // Subtle gradient accent at top
            VStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.12),
                                Theme.Colors.accent.opacity(0.06),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 300)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Fox mascot
                Text("\u{1F98A}")
                    .font(.system(size: 100))
                    .scaleEffect(foxBounce ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: foxBounce
                    )
                    .opacity(titleOpacity)

                Spacer().frame(height: 16)

                // App title
                Text("PROGRESSION")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(titleScale)
                    .opacity(titleOpacity)

                Spacer().frame(height: 12)

                // Welcome subtitle
                Text("Welcome to get you on track\nand grow with Progression!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Spacer().frame(height: 8)

                // Typewriter tagline
                Text(taglineText)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .opacity(titleOpacity)
                    .frame(height: 20)

                Spacer()

                // Sign-in buttons
                VStack(spacing: 14) {
                    // Google Sign-In button
                    Button {
                        Task {
                            await authService.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
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

                    // Apple Sign-In button (placeholder)
                    Button {
                        // Apple Sign-In placeholder
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                            Text("Sign in with Apple")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.Colors.card)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Layout.buttonRadius)
                                .stroke(Theme.Colors.cardBorder, lineWidth: 1.5)
                        )
                    }
                    .disabled(true)
                    .opacity(0.6)

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.danger)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // Email sign-in link
                Button {
                    // Email sign-in placeholder
                } label: {
                    Text("Sign in with Email")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Colors.primary)
                        .underline()
                }

                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                titleScale = 1.0
                titleOpacity = 1.0
            }
            foxBounce = true
            startTypewriter()
        }
    }

    private func startTypewriter() {
        taglineText = ""
        for (i, char) in fullTagline.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(i) * 0.04) {
                taglineText += String(char)
            }
        }
    }
}
