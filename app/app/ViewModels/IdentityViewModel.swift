import Foundation

@Observable
class IdentityViewModel {
    var identities: [IdentityResponse] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIService.shared

    @MainActor
    func loadIdentities() async {
        isLoading = identities.isEmpty
        do {
            identities = try await api.listIdentities()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func createIdentity(name: String, emoji: String, colorHex: String) async -> Bool {
        do {
            let body = IdentityCreate(name: name, emoji: emoji, colorHex: colorHex)
            _ = try await api.createIdentity(body)
            HapticManager.success()
            await loadIdentities()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func updateIdentity(_ id: UUID, name: String?, emoji: String?, colorHex: String?) async {
        do {
            let body = IdentityUpdate(name: name, emoji: emoji, colorHex: colorHex)
            _ = try await api.updateIdentity(id, body: body)
            HapticManager.success()
            await loadIdentities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteIdentity(_ id: UUID) async {
        do {
            try await api.deleteIdentity(id)
            HapticManager.warning()
            await loadIdentities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
