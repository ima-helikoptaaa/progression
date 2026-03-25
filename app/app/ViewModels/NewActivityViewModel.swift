import Foundation

@Observable
class NewActivityViewModel {
    var name = ""
    var emoji = "\u{2B50}"
    var unit = "Minutes"
    var customUnitName = ""
    var baseTarget: Double = 5
    var colorHex = "#FF6B35"
    var isCreating = false
    var errorMessage: String?
    var identityId: UUID?
    var cueTime = ""
    var cueLocation = ""
    var trackingMode = "continuous"

    private let api = APIService.shared

    let units = ["Minutes", "Reps", "Pages", "Miles", "Sets", "Custom"]
    let predefinedUnits = ["Minutes", "Reps", "Pages", "Miles", "Sets"]
    let colorOptions = Theme.Colors.activityColors

    // Top 13 icons shown by default (fits 2 rows of 7 with the "..." button)
    let quickEmojis = [
        "\u{1F3C3}", "\u{1F4DA}", "\u{1F4AA}", "\u{1F9D8}", "\u{270D}\u{FE0F}", "\u{1F4A7}", "\u{1F9E0}",
        "\u{1F525}", "\u{1F6B4}", "\u{1F3CB}\u{FE0F}", "\u{1F634}", "\u{1F957}", "\u{1F48A}"
    ]

    // Full set revealed on tap
    let allEmojis = [
        "\u{1F3C3}", "\u{1F4DA}", "\u{1F4AA}", "\u{1F9D8}", "\u{270D}\u{FE0F}", "\u{1F4A7}", "\u{1F9E0}",
        "\u{1F525}", "\u{1F6B4}", "\u{1F3CB}\u{FE0F}", "\u{1F634}", "\u{1F957}", "\u{1F48A}",
        "\u{2B50}", "\u{1F3B5}", "\u{1F331}", "\u{1F3AF}", "\u{1F4A1}", "\u{1F3CA}", "\u{1F9D7}",
        "\u{1F3A8}", "\u{1F4DD}", "\u{1F9F9}", "\u{1F415}", "\u{2615}", "\u{1F4B0}", "\u{1F3AE}",
        "\u{1F4F1}", "\u{1F6B6}", "\u{2764}\u{FE0F}", "\u{1F30D}", "\u{1F3B6}", "\u{1F4F8}", "\u{1F52C}"
    ]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var effectiveUnit: String {
        if unit == "Custom" {
            let trimmed = customUnitName.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Units" : trimmed
        }
        return unit
    }

    @MainActor
    func createActivity(userPoints: Int, existingCount: Int) async -> Bool {
        guard isValid else { return false }
        isCreating = true
        do {
            let body = ActivityCreate(
                name: name.trimmingCharacters(in: .whitespaces),
                emoji: emoji,
                unit: effectiveUnit,
                baseTarget: baseTarget,
                stepSize: 1,
                colorHex: colorHex,
                identityId: identityId,
                cueTime: cueTime.isEmpty ? nil : cueTime,
                cueLocation: cueLocation.isEmpty ? nil : cueLocation,
                trackingMode: trackingMode
            )
            _ = try await api.createActivity(body)
            HapticManager.success()
            isCreating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
            return false
        }
    }
}
