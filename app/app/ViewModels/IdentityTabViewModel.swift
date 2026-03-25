import Foundation

@Observable
class IdentityTabViewModel {
    var identities: [IdentityResponse] = []
    var statsMap: [UUID: IdentityStatsResponse] = [:]
    var isLoading = false
    var errorMessage: String?
    var showCreateSheet = false
    var editingIdentity: IdentityResponse?
    var showDeleteConfirm = false
    var identityToDelete: IdentityResponse?

    private let api = APIService.shared

    @MainActor
    func load() async {
        isLoading = identities.isEmpty
        do {
            identities = try await api.listIdentities()
            await loadAllStats()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    private func loadAllStats() async {
        await withTaskGroup(of: (UUID, IdentityStatsResponse?).self) { group in
            for identity in identities {
                group.addTask {
                    let stats = try? await self.api.getIdentityStats(identity.id)
                    return (identity.id, stats)
                }
            }
            for await (id, stats) in group {
                if let stats {
                    statsMap[id] = stats
                }
            }
        }
    }

    @MainActor
    func createIdentity(name: String, emoji: String, colorHex: String) async -> Bool {
        do {
            let body = IdentityCreate(name: name, emoji: emoji, colorHex: colorHex)
            _ = try await api.createIdentity(body)
            HapticManager.success()
            await load()
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
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteIdentity(_ id: UUID) async {
        do {
            try await api.deleteIdentity(id)
            HapticManager.warning()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
