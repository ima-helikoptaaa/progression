import Foundation
import SwiftUI
import GoogleSignIn
import FirebaseAuth

@Observable
class AuthService {
    var authState: AuthState = .loading
    var currentUser: UserResponse?
    var errorMessage: String?

    // TODO: Set to false once Firebase & GoogleSignIn SPM packages are added
    private let devMode = false

    private let api = APIService.shared

    init() {
        if devMode {
            authState = .unauthenticated
            return
        }
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            api.authToken = token
            Task { await restoreSession() }
        } else {
            authState = .unauthenticated
        }
    }

    @MainActor
    func signInWithGoogle() async {
        if devMode {
            currentUser = UserResponse(
                id: UUID(),
                firebaseUid: "dev-uid",
                email: "dev@progression.app",
                displayName: "Dev User",
                photoUrl: nil,
                timezone: "UTC",
                totalPoints: 3,
                lifetimePoints: 5,
                createdAt: ISO8601DateFormatter().string(from: .now),
                updatedAt: ISO8601DateFormatter().string(from: .now)
            )
            authState = .onboarding
            return
        }

        // NOTE: Once you add the Firebase & GoogleSignIn SPM packages:
        // 1. Add these imports at the top of the file:
        //    import GoogleSignIn
        //    import FirebaseAuth
        // 2. Set devMode = false
        // 3. Uncomment the block below and remove the stub above

        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = windowScene.windows.first?.rootViewController else {
                errorMessage = "Cannot find root view controller"
                return
            }

            let gidResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let googleIdToken = gidResult.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google ID token"
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: googleIdToken,
                accessToken: gidResult.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            guard let firebaseIdToken = try await authResult.user.getIDToken() as String? else {
                errorMessage = "Failed to get Firebase token"
                return
            }

            api.authToken = firebaseIdToken
            let user = try await api.login(idToken: firebaseIdToken)
            UserDefaults.standard.set(firebaseIdToken, forKey: "auth_token")
            currentUser = user

            let activities = try await api.listActivities()
            authState = activities.isEmpty ? .onboarding : .authenticated
        } catch {
            errorMessage = error.localizedDescription
            api.authToken = nil
            authState = .unauthenticated
        }
    }

    @MainActor
    func completeOnboarding() {
        authState = .authenticated
    }

    @MainActor
    func signOut() {
        // When Firebase is added, also call:
        // GIDSignIn.sharedInstance.signOut()
        // try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "auth_token")
        api.authToken = nil
        currentUser = nil
        authState = .unauthenticated
    }

    @MainActor
    private func restoreSession() async {
        do {
            let user = try await api.getMe()
            currentUser = user
            authState = .authenticated
        } catch {
            signOut()
        }
    }

    @MainActor
    func refreshUser() async {
        if devMode { return }
        if let user = try? await api.getMe() {
            currentUser = user
        }
    }

    @MainActor
    func updatePoints(_ newTotal: Int) {
        guard let user = currentUser else { return }
        currentUser = UserResponse(
            id: user.id, firebaseUid: user.firebaseUid, email: user.email,
            displayName: user.displayName, photoUrl: user.photoUrl,
            timezone: user.timezone, totalPoints: newTotal,
            lifetimePoints: user.lifetimePoints,
            createdAt: user.createdAt, updatedAt: user.updatedAt
        )
    }
}
