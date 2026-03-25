import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                LoginView()
            case .onboarding:
                OnboardingView()
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.authState)
    }
}

struct SplashView: View {
    @State private var foxScale: CGFloat = 0.6
    @State private var foxOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("\u{1F98A}")
                    .font(.system(size: 80))
                    .scaleEffect(foxScale)
                    .opacity(foxOpacity)

                Text("Progression")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primary)
                    .opacity(foxOpacity)

                ProgressView()
                    .tint(Theme.Colors.primary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                foxScale = 1.0
                foxOpacity = 1.0
            }
        }
    }
}
