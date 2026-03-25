import SwiftUI

struct CompleteActivitySheet: View {
    let activity: ActivityResponse
    let onComplete: (Double, String?) async -> Bool
    @Environment(\.dismiss) private var dismiss

    @State private var currentValue: Double = 0
    @State private var notes: String = ""
    @State private var didComplete = false
    @State private var isSubmitting = false
    @State private var submitError: String?

    private var isOverchargeMode: Bool {
        activity.completedToday
    }

    private var target: Double {
        activity.currentTarget
    }

    private var isDiscrete: Bool {
        if let mode = activity.trackingMode {
            return mode == "discrete"
        }
        let timeUnits = ["minutes", "hours", "seconds", "mins", "hrs", "secs"]
        return !timeUnits.contains(activity.unit.lowercased()) && target == floor(target) && target > 1
    }

    private var activityColor: Color {
        Color(hex: String(activity.colorHex.dropFirst()))
    }

    private var progress: Double {
        guard target > 0 else { return 0 }
        let totalDone = (activity.valueDoneToday ?? 0) + currentValue
        return min(totalDone / target, 1.0)
    }

    private var totalAfterLog: Double {
        (activity.valueDoneToday ?? 0) + currentValue
    }

    private var overchargeText: String? {
        guard isOverchargeMode, target > 0 else { return nil }
        let mult = totalAfterLog / target
        if mult <= 1 { return nil }
        if mult == floor(mult) { return "\(Int(mult))x target" }
        return String(format: "%.1fx target", mult)
    }

    private var formattedValue: String {
        if currentValue == floor(currentValue) {
            return "\(Int(currentValue))"
        }
        return String(format: "%.1f", currentValue)
    }

    private var canLog: Bool {
        currentValue > 0 && !isSubmitting
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Theme.Colors.cardBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 12)

            // Header - always pinned at top
            header
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // Scrollable content area
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if didComplete {
                        completedView
                            .frame(minHeight: 200)
                    } else if isDiscrete {
                        discreteInput
                    } else {
                        continuousInput
                    }
                }
                .padding(.bottom, 16)
            }

            // Bottom area - always pinned at bottom
            if !didComplete {
                bottomSection
            }
        }
        .background(Theme.Colors.background)
        .presentationDetents([.fraction(0.65), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
        .interactiveDismissDisabled(isSubmitting)
        .onAppear {
            if isDiscrete {
                currentValue = 1
            } else {
                currentValue = target
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text(activity.emoji)
                .font(.system(size: 32))
                .frame(width: 52, height: 52)
                .background(activityColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text(activity.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if isOverchargeMode {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("Already done \u{00B7} Log more")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.accent)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.Colors.primary)
                        Text("\(activity.currentStreak) \u{2192} \(activity.currentStreak + 1)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)

                        if FibonacciHelper.isFibonacciDay(activity.currentStreak + 1) {
                            HStack(spacing: 3) {
                                Image(systemName: Theme.Icons.pointIcon)
                                    .font(.system(size: 9))
                                Text("+1")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(Theme.Colors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.primary.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
            }
            .disabled(isSubmitting)
        }
    }

    // MARK: - Discrete Input

    private var discreteInput: some View {
        VStack(spacing: 20) {
            // Segmented progress bar
            let segmentCount = Int(target)
            let alreadyDone = Int(activity.valueDoneToday ?? 0)
            let willBeDone = alreadyDone + Int(currentValue)

            HStack(spacing: 3) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    Capsule()
                        .fill(
                            index < alreadyDone
                                ? activityColor.opacity(0.4)
                                : index < willBeDone
                                    ? activityColor
                                    : activityColor.opacity(0.12)
                        )
                        .frame(height: 6)
                        .animation(Theme.Animation.spring, value: currentValue)
                }
            }
            .padding(.horizontal, 20)

            // Large value display
            VStack(spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(activityColor)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: currentValue)

                Text(activity.unit.lowercased())
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                if let ovText = overchargeText {
                    Text(ovText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.top, 2)
                }
            }

            // +/- stepper
            HStack(spacing: 32) {
                Button {
                    if currentValue > 1 { currentValue -= 1 }
                    HapticManager.selection()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(currentValue > 1 ? Theme.Colors.textSecondary : Theme.Colors.textTertiary)
                        .frame(width: 56, height: 56)
                        .background(Theme.Colors.card)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.Colors.cardBorder, lineWidth: 1))
                }
                .disabled(currentValue <= 1)

                Button {
                    currentValue += 1
                    HapticManager.selection()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(activityColor)
                        .clipShape(Circle())
                        .shadow(color: activityColor.opacity(0.3), radius: 6, y: 3)
                }
            }

            // Quick-fill remaining (if not overcharge)
            if !isOverchargeMode {
                let remaining = max(0, target - (activity.valueDoneToday ?? 0))
                if remaining > 1 && currentValue != remaining {
                    Button {
                        currentValue = remaining
                        HapticManager.selection()
                    } label: {
                        Text("Fill remaining (\(Int(remaining)))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(activityColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(activityColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Continuous Input

    private var continuousInput: some View {
        VStack(spacing: 20) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(activityColor.opacity(0.12), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(activityColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.spring, value: progress)

                VStack(spacing: 4) {
                    Text(formattedValue)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(activityColor)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: currentValue)

                    if target == floor(target) {
                        Text("of \(Int(target)) \(activity.unit.lowercased())")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    } else {
                        Text(String(format: "of %.1f %@", target, activity.unit.lowercased()))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    if let ovText = overchargeText {
                        Text(ovText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
            .frame(width: 160, height: 160)

            // Slider
            VStack(spacing: 8) {
                Slider(value: $currentValue, in: 0.0...max(target * 2, 1), step: target <= 10 ? 0.5 : 1.0)
                    .tint(activityColor)
                    .padding(.horizontal, 20)

                // Quick buttons
                HStack(spacing: 8) {
                    quickButton("25%", fraction: 0.25)
                    quickButton("50%", fraction: 0.5)
                    quickButton("75%", fraction: 0.75)
                    quickButton("100%", fraction: 1.0)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func quickButton(_ label: String, fraction: Double) -> some View {
        let val = target * fraction
        let isSelected = abs(currentValue - val) < 0.01
        return Button {
            currentValue = val
            HapticManager.selection()
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? activityColor : Theme.Colors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 10) {
            // Notes
            TextField("Notes (optional)", text: $notes)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(12)
                .background(Theme.Colors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, 20)
                .submitLabel(.done)

            // Error
            if let error = submitError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 12))
                }
                .foregroundStyle(Theme.Colors.danger)
                .padding(.horizontal, 20)
            }

            // Log button
            Button {
                submitCompletion()
            } label: {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Log \(formattedValue) \(activity.unit.lowercased())")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(canLog ? activityColor : Color.gray.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: canLog ? activityColor.opacity(0.3) : .clear, radius: 8, y: 4)
            .disabled(!canLog)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 28)
        .background(
            Theme.Colors.background
                .shadow(.drop(color: .black.opacity(0.05), radius: 8, y: -4))
        )
    }

    // MARK: - Completed

    private var completedView: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.success)
                .shadow(color: Theme.Colors.success.opacity(0.3), radius: 10)

            Text("Logged \(formattedValue) \(activity.unit.lowercased())")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            if let ovText = overchargeText {
                Text(ovText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.accent)
            }

            Spacer()
        }
    }

    // MARK: - Submit

    private func submitCompletion() {
        guard canLog else { return }
        isSubmitting = true
        submitError = nil

        let finalValue = currentValue
        let finalNotes = notes.isEmpty ? nil : notes

        Task {
            let success = await onComplete(finalValue, finalNotes)
            if success {
                withAnimation(Theme.Animation.spring) {
                    didComplete = true
                }
                HapticManager.success()
                isSubmitting = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                }
            } else {
                isSubmitting = false
                submitError = "Failed to save. Check your connection."
                HapticManager.warning()
            }
        }
    }
}
