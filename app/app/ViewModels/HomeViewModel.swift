import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var activities: [ActivityResponse] = []
    var identities: [IdentityResponse] = []
    var stacks: [HabitStackResponse] = []
    var isLoading = false
    var errorMessage: String?
    var completionResult: CompletionResponse?
    var showCelebration = false
    var penalties: [PenaltyInfo] = []
    var groupByIdentity = false
    var nextStackActivityId: UUID?

    private let api = APIService.shared

    var completedCount: Int {
        activities.filter(\.completedToday).count
    }

    var totalCount: Int {
        activities.filter { !$0.isPaused }.count
    }

    var pendingActivities: [ActivityResponse] {
        sortedActivities(activities.filter { !$0.completedToday && !$0.isPaused })
    }

    var completedActivities: [ActivityResponse] {
        sortedActivities(activities.filter { $0.completedToday })
    }

    var pausedActivities: [ActivityResponse] {
        activities.filter { $0.isPaused }
    }

    // Group activities by identity
    var groupedActivities: [(identity: IdentityResponse?, activities: [ActivityResponse])] {
        guard groupByIdentity else { return [] }
        var groups: [(identity: IdentityResponse?, activities: [ActivityResponse])] = []

        for identity in identities {
            let matching = activities.filter { $0.identityId == identity.id && !$0.isPaused }
            if !matching.isEmpty {
                groups.append((identity: identity, activities: matching))
            }
        }

        // General (unassigned) section
        let unassigned = activities.filter { $0.identityId == nil && !$0.isPaused }
        if !unassigned.isEmpty {
            groups.append((identity: nil, activities: unassigned))
        }

        return groups
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good\nmorning"
        case 12..<17: return "Good\nafternoon"
        case 17..<21: return "Good\nevening"
        default: return "Good\nnight"
        }
    }

    var motivationalMessage: String {
        let remaining = totalCount - completedCount
        if totalCount == 0 { return "Add your first activity to get started!" }
        if remaining == 0 { return "All done for today! Great work." }
        if remaining == 1 { return "Just 1 more to go!" }
        return "Keep it up! \(remaining) more to go."
    }

    // Sort activities keeping stacked ones together
    private func sortedActivities(_ list: [ActivityResponse]) -> [ActivityResponse] {
        var result: [ActivityResponse] = []
        var added = Set<UUID>()

        for activity in list.sorted(by: { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }) {
            guard !added.contains(activity.id) else { continue }

            if let stackId = activity.stackId {
                // Add all activities in this stack consecutively
                let stackActivities = list
                    .filter { $0.stackId == stackId }
                    .sorted { ($0.stackOrder ?? 0) < ($1.stackOrder ?? 0) }
                for sa in stackActivities {
                    if !added.contains(sa.id) {
                        result.append(sa)
                        added.insert(sa.id)
                    }
                }
            } else {
                result.append(activity)
                added.insert(activity.id)
            }
        }

        return result
    }

    @MainActor
    func loadActivities() async {
        isLoading = activities.isEmpty
        do {
            async let activitiesReq = api.listActivities()
            async let identitiesReq = api.listIdentities()
            async let stacksReq = api.listStacks()
            activities = try await activitiesReq
            identities = try await identitiesReq
            stacks = try await stacksReq
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Check for missed-day penalties and surface them.
    /// Also syncs the user's current point total.
    @MainActor
    func checkPenalties() async -> (penalties: [PenaltyInfo], totalPoints: Int)? {
        do {
            let response = try await api.checkPenalties()
            if !response.penalties.isEmpty {
                penalties = response.penalties
            }
            return (response.penalties, response.totalPoints)
        } catch {
            return nil
        }
    }

    /// Returns (success, totalPoints) so the caller can update points immediately
    @MainActor
    func completeActivity(_ activity: ActivityResponse, value: Double? = nil, notes: String? = nil) async -> (success: Bool, totalPoints: Int?) {
        do {
            let body = CompleteRequest(value: value ?? activity.currentTarget, notes: notes)
            let result = try await api.completeActivity(activity.id, body: body)
            completionResult = result
            if result.isMilestone {
                showCelebration = true
            }
            HapticManager.success()

            // Check if there's a next activity in the stack
            if let stackId = activity.stackId,
               let stackOrder = activity.stackOrder {
                let nextInStack = activities.first {
                    $0.stackId == stackId &&
                    ($0.stackOrder ?? 0) == stackOrder + 1 &&
                    !$0.completedToday
                }
                if let next = nextInStack {
                    nextStackActivityId = next.id
                }
            }

            await loadActivities()
            return (true, result.totalPoints)
        } catch {
            errorMessage = error.localizedDescription
            return (false, nil)
        }
    }

    @MainActor
    func quickComplete(_ activity: ActivityResponse) async {
        _ = await completeActivity(activity, value: activity.currentTarget, notes: nil)
    }

    /// Increment a discrete activity by 1 unit (e.g., 1 glass of water)
    @MainActor
    func incrementActivity(_ activity: ActivityResponse) async -> (success: Bool, totalPoints: Int?) {
        return await completeActivity(activity, value: 1, notes: nil)
    }

    @MainActor
    func togglePause(_ activity: ActivityResponse) async {
        do {
            _ = try await api.togglePause(activity.id)
            HapticManager.impact(.medium)
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteActivity(_ activity: ActivityResponse) async {
        do {
            try await api.deleteActivity(activity.id)
            HapticManager.warning()
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Drag-to-Stack

    @MainActor
    func createStackFromDrop(sourceId: UUID, targetId: UUID) async {
        guard sourceId != targetId else { return }

        let source = activities.first { $0.id == sourceId }
        let target = activities.first { $0.id == targetId }
        guard let source, let target else { return }

        do {
            if let targetStackId = target.stackId {
                // Target is already in a stack, add source to it
                _ = try await api.addActivityToStack(
                    targetStackId,
                    body: HabitStackAddActivity(activityId: source.id)
                )
            } else if let sourceStackId = source.stackId {
                // Source is already in a stack, add target to it
                _ = try await api.addActivityToStack(
                    sourceStackId,
                    body: HabitStackAddActivity(activityId: target.id)
                )
            } else {
                // Neither in a stack, create new stack
                let stackName = "\(source.name) + \(target.name)"
                let stack = try await api.createStack(HabitStackCreate(name: stackName))
                _ = try await api.addActivityToStack(
                    stack.id,
                    body: HabitStackAddActivity(activityId: source.id, order: 0)
                )
                _ = try await api.addActivityToStack(
                    stack.id,
                    body: HabitStackAddActivity(activityId: target.id, order: 1)
                )
            }
            HapticManager.success()
            await loadActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
