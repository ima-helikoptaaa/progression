import Foundation
import UIKit

@Observable
class ActivityDetailViewModel {
    var activity: ActivityResponse
    var history: ActivityHistoryResponse?
    var isLoading = false
    var errorMessage: String?

    private let api = APIService.shared

    init(activity: ActivityResponse) {
        self.activity = activity
    }

    var milestones: [(value: Int, reached: Bool)] {
        FibonacciHelper.checkpoints.map { checkpoint in
            (value: checkpoint, reached: activity.currentStreak >= checkpoint)
        }
    }

    var historyValues: [Double] {
        history?.entries.map(\.value) ?? []
    }

    var historyTarget: Double {
        activity.currentTarget
    }

    @MainActor
    func loadHistory() async {
        isLoading = true
        do {
            history = try await api.getActivityHistory(activity.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func upgrade(newTarget: Double) async {
        do {
            let body = SpendRequest(action: "upgrade", activityId: activity.id, newTarget: newTarget)
            _ = try await api.spendPoints(body)
            HapticManager.success()
            let activities = try await api.listActivities()
            if let updated = activities.first(where: { $0.id == activity.id }) {
                activity = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func togglePause() async {
        do {
            let updated = try await api.togglePause(activity.id)
            activity = updated
            HapticManager.impact(.medium)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteActivity() async -> Bool {
        do {
            try await api.deleteActivity(activity.id)
            HapticManager.warning()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func refreshActivity() async {
        do {
            let activities = try await api.listActivities()
            if let updated = activities.first(where: { $0.id == activity.id }) {
                activity = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
