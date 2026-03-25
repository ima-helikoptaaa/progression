import Foundation

// MARK: - Auth State

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case onboarding
    case authenticated
}

// MARK: - User

struct UserResponse: Codable, Identifiable {
    let id: UUID
    let firebaseUid: String
    let email: String
    let displayName: String?
    let photoUrl: String?
    let timezone: String
    let totalPoints: Int
    let lifetimePoints: Int
    let createdAt: String
    let updatedAt: String
}

struct UserUpdate: Codable {
    var displayName: String?
    var timezone: String?
}

// MARK: - Activity

struct ActivityResponse: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let emoji: String
    let unit: String
    let baseTarget: Double
    let currentTarget: Double
    let stepSize: Double
    let currentStreak: Int
    let bestStreak: Int
    let lastCompletedDate: String?
    let isActive: Bool
    let isPaused: Bool
    let colorHex: String
    let sortOrder: Int
    let identityId: UUID?
    let stackId: UUID?
    let stackOrder: Int?
    let cueTime: String?
    let cueLocation: String?
    let createdAt: String
    let updatedAt: String
    let nextMilestone: Int
    let prevMilestone: Int
    let progressToNext: Double
    let completedToday: Bool
    let valueDoneToday: Double?
    let trackingMode: String?
}

struct ActivityCreate: Codable {
    let name: String
    var emoji: String = "⭐"
    var unit: String = "Minutes"
    var baseTarget: Double = 1.0
    var currentTarget: Double? = nil
    var stepSize: Double = 1.0
    var colorHex: String = "#FF6B35"
    var sortOrder: Int = 0
    var identityId: UUID? = nil
    var cueTime: String? = nil
    var cueLocation: String? = nil
    var trackingMode: String = "continuous"
}

struct ActivityUpdate: Codable {
    var name: String? = nil
    var emoji: String? = nil
    var colorHex: String? = nil
    var sortOrder: Int? = nil
    var unit: String? = nil
    var identityId: UUID? = nil
    var cueTime: String? = nil
    var cueLocation: String? = nil
    var trackingMode: String? = nil
}

struct CompleteRequest: Codable {
    var value: Double? = nil
    var notes: String? = nil
}

struct CompletionResponse: Codable {
    let newStreak: Int
    let earnedPoint: Bool
    let isMilestone: Bool
    let nextMilestone: Int
    let prevMilestone: Int
    let progressToNext: Double
    let totalPoints: Int
    let isOvercharge: Bool?
    let valueDoneToday: Double?
}

// MARK: - Points

struct PointBalanceResponse: Codable {
    let totalPoints: Int
    let lifetimePoints: Int
    let spentPoints: Int
    let transactions: [PointTransactionResponse]
}

struct PointTransactionResponse: Codable, Identifiable {
    let id: UUID
    let amount: Int
    let transactionType: String
    let activityId: UUID?
    let description: String
    let createdAt: String
}

struct SpendRequest: Codable {
    let action: String
    var activityId: UUID? = nil
    var newTarget: Double? = nil
}

// MARK: - Stats

struct OverviewResponse: Codable {
    let totalCompletions: Int
    let bestStreak: Int
    let totalPointsEarned: Int
    let activeActivities: Int
    let currentWeekCompletions: Int
    let previousWeekCompletions: Int
}

struct HeatmapEntry: Codable, Identifiable {
    let date: String
    let count: Int
    let ratio: Double
    let totalCompletions: Int?
    let intensity: Double?

    var id: String { date }
}

struct HeatmapResponse: Codable {
    let entries: [HeatmapEntry]
    let totalActivities: Int
}

struct ActivityHistoryEntry: Codable {
    let date: String
    let value: Double
    let target: Double
    let streak: Int
    let earnedPoint: Bool
}

struct ActivityHistoryResponse: Codable {
    let activityId: UUID
    let activityName: String
    let entries: [ActivityHistoryEntry]
}

// MARK: - Penalty

struct PenaltyInfo: Codable, Identifiable {
    let activityId: String
    let activityName: String
    let oldStreak: Int
    let newStreak: Int
    let oldTarget: Double
    let newTarget: Double

    var id: String { activityId }
}

struct PenaltyCheckResponse: Codable {
    let penalties: [PenaltyInfo]
    let totalPoints: Int
}

// MARK: - Identity

struct IdentityResponse: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let emoji: String
    let colorHex: String
    let sortOrder: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
}

struct IdentityCreate: Codable {
    let name: String
    var emoji: String = "🎯"
    var colorHex: String = "#FF6B35"
    var sortOrder: Int = 0
}

struct IdentityUpdate: Codable {
    var name: String? = nil
    var emoji: String? = nil
    var colorHex: String? = nil
    var sortOrder: Int? = nil
}

// MARK: - Identity Stats

struct IdentityActivityStat: Codable, Identifiable {
    let activityId: UUID
    let name: String
    let emoji: String
    let currentStreak: Int
    let bestStreak: Int
    let completedToday: Bool
    let colorHex: String

    var id: UUID { activityId }
}

struct IdentityStatsResponse: Codable {
    let identityId: UUID
    let totalActivities: Int
    let totalCompletions: Int
    let bestStreak: Int
    let weeklyCompletionRate: Double
    let activityStats: [IdentityActivityStat]
}

// MARK: - Habit Stack

struct HabitStackResponse: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let isActive: Bool
    let createdAt: String
    let activityIds: [UUID]
}

struct HabitStackCreate: Codable {
    let name: String
}

struct HabitStackAddActivity: Codable {
    let activityId: UUID
    var order: Int = 0
}

struct HabitStackReorder: Codable {
    let activityIds: [UUID]
}
