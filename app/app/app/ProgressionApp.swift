import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct ProgressionApp: App {
    @State private var authService = AuthService()
    @State private var appState = AppState()

    init() {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "103377356088-0ld1h153ilv360je2ch7a367gksel3sd.apps.googleusercontent.com"
        )

        // Configure tab bar appearance for warm theme
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color(hex: "FFF8F0"))
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Configure navigation bar for warm theme
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color(hex: "FFF8F0"))
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "2D1B00"))]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color(hex: "2D1B00"))]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(appState)
                .preferredColorScheme(.light)
        }
    }
}

@Observable
class AppState {
    var penalties: [PenaltyInfo] = []
    var showPenaltyBanner = false

    func setPenalties(_ penalties: [PenaltyInfo]) {
        self.penalties = penalties
        self.showPenaltyBanner = !penalties.isEmpty
    }

    func dismissPenalties() {
        showPenaltyBanner = false
    }
}
