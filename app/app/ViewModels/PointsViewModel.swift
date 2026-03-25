import Foundation

@Observable
class PointsViewModel {
    var balance: PointBalanceResponse?
    var isLoading = false
    var errorMessage: String?

    private let api = APIService.shared

    @MainActor
    func loadPoints() async {
        isLoading = balance == nil
        do {
            balance = try await api.getPoints()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
