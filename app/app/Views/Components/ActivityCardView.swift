import SwiftUI

struct ActivityCardView: View {
    let activity: ActivityResponse
    let identity: IdentityResponse?
    let onComplete: () -> Void
    let onTap: () -> Void
    let onIncrement: (() -> Void)?
    var showStackConnector: Bool = false

    init(
        activity: ActivityResponse,
        identity: IdentityResponse?,
        onComplete: @escaping () -> Void,
        onTap: @escaping () -> Void,
        onIncrement: (() -> Void)? = nil,
        showStackConnector: Bool = false
    ) {
        self.activity = activity
        self.identity = identity
        self.onComplete = onComplete
        self.onTap = onTap
        self.onIncrement = onIncrement
        self.showStackConnector = showStackConnector
    }

    private var activityColor: Color {
        Color(hex: String(activity.colorHex.dropFirst()))
    }

    private var valueDone: Double {
        activity.valueDoneToday ?? 0
    }

    private var target: Double {
        activity.currentTarget
    }

    private var todayProgress: Double {
        guard target > 0 else { return 0 }
        return min(valueDone / target, 1.0)
    }

    private var overflowMultiplier: Double {
        guard target > 0 else { return 0 }
        return valueDone / target
    }

    private var isDiscrete: Bool {
        if let mode = activity.trackingMode {
            return mode == "discrete"
        }
        let timeUnits = ["minutes", "hours", "seconds", "mins", "hrs", "secs"]
        return !timeUnits.contains(activity.unit.lowercased()) && target == floor(target) && target > 1
    }

    private var isOverflow: Bool {
        valueDone > target && activity.completedToday
    }

    private var overchargeMultiplier: String? {
        guard isOverflow, target > 0 else { return nil }
        let mult = valueDone / target
        if mult == floor(mult) {
            return "\(Int(mult))x"
        }
        return String(format: "%.1fx", mult)
    }

    private var progressLabel: String {
        if isDiscrete {
            return "\(Int(valueDone)) of \(Int(target)) \(activity.unit.lowercased())"
        } else {
            let unitShort = shortUnit(activity.unit)
            if target == floor(target) && valueDone == floor(valueDone) {
                return "\(Int(valueDone)) / \(Int(target)) \(unitShort)"
            }
            return String(format: "%.1f / %.1f \(unitShort)", valueDone, target)
        }
    }

    private var percentageText: String {
        let pct = Int(todayProgress * 100)
        return "\(pct)%"
    }

    private func shortUnit(_ unit: String) -> String {
        switch unit.lowercased() {
        case "minutes": return "min"
        case "hours": return "hrs"
        case "seconds": return "sec"
        default: return unit.lowercased()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showStackConnector {
                Rectangle()
                    .fill(Theme.Colors.textTertiary.opacity(0.4))
                    .frame(width: 2, height: 10)
            }

            VStack(alignment: .leading, spacing: 0) {
                // Top: emoji + name/cue + action button
                topSection
                    .padding(.bottom, 6)

                // Target metric
                Text("\(Int(target)) \(activity.unit)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(activity.completedToday && !isOverflow ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .padding(.bottom, 10)

                // Progress info + bar
                progressSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                    .fill(Theme.Colors.card)
                    .shadow(color: Theme.Colors.foxOrange.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                    .stroke(
                        activity.completedToday
                            ? activityColor.opacity(0.25)
                            : Theme.Colors.cardBorder,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .opacity(activity.isPaused ? 0.45 : (activity.completedToday && !isOverflow ? 0.75 : 1))
        }
    }

    // MARK: - Top Section

    private var topSection: some View {
        HStack(spacing: 10) {
            // Emoji in tinted circle
            Text(activity.emoji)
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(activityColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Name + cue time + overcharge badge
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text(activity.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(activityColor)
                        .lineLimit(1)

                    if let cueText = cueTimeText {
                        Text(" \u{00B7} \(cueText)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                if let mult = overchargeMultiplier {
                    Text(mult + " target")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            Spacer(minLength: 0)

            // Action button
            if !activity.isPaused {
                actionButton
            }
        }
    }

    private var cueTimeText: String? {
        if let t = activity.cueTime, !t.isEmpty { return t }
        if let l = activity.cueLocation, !l.isEmpty { return l }
        if isDiscrete { return "all day" }
        return nil
    }

    @ViewBuilder
    private var actionButton: some View {
        if isDiscrete && !activity.completedToday {
            // "+" button for discrete activities
            Button {
                onIncrement?() ?? onComplete()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(activityColor)
                    .frame(width: 38, height: 38)
                    .background(activityColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(activityColor.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        } else {
            // Checkmark button
            Button {
                onComplete()
            } label: {
                if activity.completedToday {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(width: 38, height: 38)
                        .background(Theme.Colors.foxCream)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Theme.Colors.cardBorder, lineWidth: 1)
                        )
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(activityColor)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Progress label + percentage
            HStack {
                if isDiscrete {
                    Text(progressLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(activityColor)
                } else {
                    Text("Progress")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(activityColor)
                    Spacer()
                    Text(progressLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(activityColor)
                }

                if isDiscrete {
                    Spacer()
                    Text(percentageText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(activityColor)
                }
            }

            // Progress bar
            if isDiscrete {
                discreteProgressBar
            } else {
                continuousProgressBar
            }
        }
    }

    // MARK: - Continuous Progress Bar

    private var continuousProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(activityColor.opacity(0.15))
                Capsule()
                    .fill(activityColor)
                    .frame(width: max(0, geo.size.width * todayProgress))
                    .animation(Theme.Animation.spring, value: todayProgress)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Discrete Progress Bar (segmented)

    private var discreteProgressBar: some View {
        let segmentCount = Int(target)
        let filledCount = Int(valueDone)

        return HStack(spacing: 3) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Capsule()
                    .fill(index < filledCount ? activityColor : activityColor.opacity(0.15))
                    .frame(height: 5)
                    .animation(Theme.Animation.spring, value: filledCount)
            }
        }
    }
}
