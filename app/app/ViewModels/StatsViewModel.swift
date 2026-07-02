import Foundation

@Observable
class StatsViewModel {
    var overview: OverviewResponse?
    var heatmap: HeatmapResponse?
    var activities: [ActivityResponse] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIService.shared

    var weeklyCompletionRate: Double {
        guard let overview, overview.activeActivities > 0 else { return 0 }
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: Date())
        let mondayOffset = dayOfWeek == 1 ? 6 : dayOfWeek - 2
        let daysElapsed = mondayOffset + 1
        let possible = overview.activeActivities * daysElapsed
        guard possible > 0 else { return 0 }
        return min(1.0, Double(overview.currentWeekCompletions) / Double(possible))
    }

    var streakInsight: String? {
        guard let longestActivity = activities.max(by: { $0.currentStreak < $1.currentStreak }),
              longestActivity.currentStreak > 0 else { return nil }
        let next = FibonacciHelper.nextFibonacci(longestActivity.currentStreak)
        let daysAway = next - longestActivity.currentStreak
        if daysAway <= 5 {
            return "\(longestActivity.emoji) \(longestActivity.name) is \(daysAway) day\(daysAway == 1 ? "" : "s") from Day \(next) milestone!"
        }
        return "\(longestActivity.emoji) \(longestActivity.name) is your longest active streak at \(longestActivity.currentStreak) days"
    }

    @MainActor
    func loadStats() async {
        isLoading = overview == nil
        do {
            async let overviewReq = api.getOverview()
            async let heatmapReq = api.getHeatmap()
            async let activitiesReq = api.listActivities()
            overview = try await overviewReq
            heatmap = try await heatmapReq
            activities = try await activitiesReq
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
