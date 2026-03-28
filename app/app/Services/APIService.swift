import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case tokenExpired
    case badRequest(String)
    case notFound
    case serverError
    case offline
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in again"
        case .tokenExpired: return "Your session has expired. Please sign in again."
        case .badRequest(let msg): return msg
        case .notFound: return "Not found"
        case .serverError: return "Something went wrong on our end. Please try again."
        case .offline: return "You appear to be offline. Check your connection and try again."
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err): return "Data error: \(err.localizedDescription)"
        }
    }
}

@Observable
class APIService {
    static let shared = APIService()

    #if DEBUG
    private let baseURL = "http://13.214.26.96/api/progression/api/v1"
    #else
    private let baseURL = "https://13.214.26.96/api/progression/api/v1"
    #endif

    var authToken: String?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var components = URLComponents(string: baseURL + path)!
        if let queryItems { components.queryItems = queryItems }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw APIError.offline
            case .timedOut:
                throw APIError.networkError(urlError)
            default:
                throw APIError.networkError(urlError)
            }
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.serverError
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            // Check if the response indicates an expired token specifically
            if let detail = try? decoder.decode(ErrorDetail.self, from: data),
               detail.detail.lowercased().contains("expired") {
                throw APIError.tokenExpired
            }
            throw APIError.unauthorized
        case 400:
            if let detail = try? decoder.decode(ErrorDetail.self, from: data) {
                throw APIError.badRequest(detail.detail)
            }
            throw APIError.badRequest("Bad request")
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError
        }
    }

    private func requestNoContent(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil
    ) async throws {
        var req = URLRequest(url: URL(string: baseURL + path)!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }
        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await URLSession.shared.data(for: req)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw APIError.offline
            default:
                throw APIError.networkError(urlError)
            }
        } catch {
            throw APIError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError
        }
    }

    // MARK: - Auth
    func login(idToken: String) async throws -> UserResponse {
        struct Body: Encodable { let idToken: String }
        return try await request("POST", path: "/auth/login", body: Body(idToken: idToken))
    }

    // MARK: - User
    func getMe() async throws -> UserResponse {
        try await request("GET", path: "/users/me")
    }

    func updateMe(_ body: UserUpdate) async throws -> UserResponse {
        try await request("PUT", path: "/users/me", body: body)
    }

    // MARK: - Activities
    func listActivities() async throws -> [ActivityResponse] {
        try await request("GET", path: "/activities")
    }

    func checkPenalties() async throws -> PenaltyCheckResponse {
        try await request("GET", path: "/activities/penalties")
    }

    func createActivity(_ body: ActivityCreate) async throws -> ActivityResponse {
        try await request("POST", path: "/activities", body: body)
    }

    func updateActivity(_ id: UUID, body: ActivityUpdate) async throws -> ActivityResponse {
        try await request("PUT", path: "/activities/\(id)", body: body)
    }

    func deleteActivity(_ id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/activities/\(id)")
    }

    func completeActivity(_ id: UUID, body: CompleteRequest) async throws -> CompletionResponse {
        try await request("POST", path: "/activities/\(id)/complete", body: body)
    }

    func togglePause(_ id: UUID) async throws -> ActivityResponse {
        try await request("POST", path: "/activities/\(id)/pause")
    }

    // MARK: - Points
    func getPoints() async throws -> PointBalanceResponse {
        try await request("GET", path: "/points")
    }

    func spendPoints(_ body: SpendRequest) async throws -> SpendResponse {
        try await request("POST", path: "/points/spend", body: body)
    }

    // MARK: - Stats
    func getOverview() async throws -> OverviewResponse {
        try await request("GET", path: "/stats/overview")
    }

    func getHeatmap(days: Int = 90) async throws -> HeatmapResponse {
        try await request("GET", path: "/stats/heatmap", queryItems: [.init(name: "days", value: "\(days)")])
    }

    func getActivityHistory(_ id: UUID, days: Int = 30) async throws -> ActivityHistoryResponse {
        try await request("GET", path: "/stats/activity/\(id)/history", queryItems: [.init(name: "days", value: "\(days)")])
    }

    func getIdentityStats(_ identityId: UUID) async throws -> IdentityStatsResponse {
        try await request("GET", path: "/stats/identity/\(identityId)")
    }

    // MARK: - Identities
    func listIdentities() async throws -> [IdentityResponse] {
        try await request("GET", path: "/identities")
    }

    func createIdentity(_ body: IdentityCreate) async throws -> IdentityResponse {
        try await request("POST", path: "/identities", body: body)
    }

    func updateIdentity(_ id: UUID, body: IdentityUpdate) async throws -> IdentityResponse {
        try await request("PUT", path: "/identities/\(id)", body: body)
    }

    func deleteIdentity(_ id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/identities/\(id)")
    }

    // MARK: - Stacks
    func listStacks() async throws -> [HabitStackResponse] {
        try await request("GET", path: "/stacks")
    }

    func createStack(_ body: HabitStackCreate) async throws -> HabitStackResponse {
        try await request("POST", path: "/stacks", body: body)
    }

    func addActivityToStack(_ stackId: UUID, body: HabitStackAddActivity) async throws -> HabitStackResponse {
        try await request("POST", path: "/stacks/\(stackId)/add", body: body)
    }

    func removeActivityFromStack(_ stackId: UUID, body: HabitStackAddActivity) async throws -> HabitStackResponse {
        try await request("POST", path: "/stacks/\(stackId)/remove", body: body)
    }

    func reorderStack(_ stackId: UUID, body: HabitStackReorder) async throws -> HabitStackResponse {
        try await request("POST", path: "/stacks/\(stackId)/reorder", body: body)
    }

    func deleteStack(_ id: UUID) async throws {
        try await requestNoContent("DELETE", path: "/stacks/\(id)")
    }
}

private struct ErrorDetail: Decodable {
    let detail: String
}

struct SpendResponse: Codable {
    var newTarget: Double?
    var remainingPoints: Int?
    var canCreate: Bool?
    var cost: Int?
}
