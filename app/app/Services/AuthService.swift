import Foundation
import SwiftUI
import GoogleSignIn
import FirebaseAuth

@Observable
class AuthService {
    var authState: AuthState = .loading
    var currentUser: UserResponse?
    var errorMessage: String?

    private let devMode = false
    private let api = APIService.shared
    private let tokenKey = "auth_token"

    init() {
        if devMode {
            authState = .unauthenticated
            return
        }
        if let token = KeychainHelper.read(key: tokenKey) {
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

        do {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                  let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
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
            let user = try await api.login(idToken: firebaseIdToken, timezone: TimeZone.current.identifier)
            KeychainHelper.save(key: tokenKey, value: firebaseIdToken)
            currentUser = user

            do {
                let activities = try await api.listActivities()
                authState = activities.isEmpty ? .onboarding : .authenticated
            } catch {
                authState = .authenticated
            }
        } catch {
            errorMessage = error.localizedDescription
            if case APIError.unauthorized = error {
                api.authToken = nil
                authState = .unauthenticated
            }
        }
    }

    @MainActor
    func completeOnboarding() {
        authState = .authenticated
    }

    @MainActor
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
        KeychainHelper.delete(key: tokenKey)
        api.authToken = nil
        currentUser = nil
        authState = .unauthenticated
    }

    /// Refresh the Firebase ID token and update the stored token
    @MainActor
    func refreshToken() async -> Bool {
        guard let firebaseUser = Auth.auth().currentUser else { return false }
        do {
            let newToken = try await firebaseUser.getIDToken(forcingRefresh: true)
            api.authToken = newToken
            KeychainHelper.save(key: tokenKey, value: newToken)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    private func restoreSession() async {
        do {
            let user = try await api.getMe()
            currentUser = user
            authState = .authenticated
        } catch let error as APIError {
            switch error {
            case .tokenExpired:
                if await refreshToken() {
                    if let user = try? await api.getMe() {
                        currentUser = user
                        authState = .authenticated
                        return
                    }
                }
                signOut()
            case .unauthorized:
                signOut()
            case .offline, .networkError:
                authState = .authenticated
            default:
                authState = .authenticated
            }
        } catch {
            authState = .authenticated
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
