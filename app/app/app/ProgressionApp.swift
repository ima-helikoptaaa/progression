import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct ProgressionApp: App {
    @State private var authService = AuthService()
    @State private var appState = AppState()

    init() {
        FirebaseApp.configure()

        let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
            ?? (Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist").flatMap { url in
                (NSDictionary(contentsOf: url)?["CLIENT_ID"] as? String)
            }) ?? ""
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        // Configure tab bar appearance for warm theme (adaptive)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Theme.Colors.background)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Configure navigation bar for warm theme (adaptive)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.Colors.background)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.Colors.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.Colors.textPrimary)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(appState)
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
