import SwiftUI

struct ActivityDetailView: View {
    @State private var viewModel: ActivityDetailViewModel
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var selectedDayEntry: ActivityHistoryEntry?
    @State private var showStackPicker = false
    @State private var showUpgradeSheet = false
    @State private var otherActivities: [ActivityResponse] = []

    init(activity: ActivityResponse) {
        _viewModel = State(initialValue: ActivityDetailViewModel(activity: activity))
    }

    private var activityColor: Color {
        Color(hex: String(viewModel.activity.colorHex.dropFirst()))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                milestonesSection
                trendChartSection
                calendarSection
                stackSection
                upgradeSection
                dangerZoneSection
                errorSection
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditSheet = true
                }
                .foregroundStyle(Theme.Colors.primary)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditActivityView(activity: viewModel.activity) {
                Task { await viewModel.refreshActivity() }
            }
        }
        .sheet(isPresented: $showStackPicker) {
            stackPickerSheet
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradeTargetSheet(activity: viewModel.activity) { newTarget in
                Task { await viewModel.upgrade(newTarget: newTarget) }
            }
        }
        .alert("Delete Activity", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteActivity() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently delete \"\(viewModel.activity.name)\" and all its history. This cannot be undone.")
        }
        .task {
            await viewModel.loadHistory()
            do {
                otherActivities = try await APIService.shared.listActivities()
            } catch {}
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Large Fibonacci ring with warm glow
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.06))
                    .frame(width: 220, height: 220)

                FibonacciRingView(
                    streak: viewModel.activity.currentStreak,
                    color: activityColor,
                    isCompleted: viewModel.activity.completedToday,
                    size: 200
                )
            }

            Text("\(viewModel.activity.emoji) \(viewModel.activity.name)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            // When/Where cue
            if let cueTime = viewModel.activity.cueTime, !cueTime.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.primary)
                    Text(cueTime)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    if let cueLocation = viewModel.activity.cueLocation, !cueLocation.isEmpty {
                        Text("\u{00B7}")
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Image(systemName: "location")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.primary)
                        Text(cueLocation)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.foxCream)
                .clipShape(Capsule())
            }

            HStack(spacing: 24) {
                statItem("Best", "\(viewModel.activity.bestStreak)")
                statItem("Current", "\(viewModel.activity.currentStreak)")
                statItem("Target", "\(Int(viewModel.activity.currentTarget))")
            }
            .padding(.top, 4)
        }
    }

    private var milestonesSection: some View {
        let current = viewModel.activity.currentStreak
        let next = viewModel.activity.nextMilestone
        let remaining = next - current

        return VStack(spacing: 16) {
            // Current streak
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.primary)
                        Text("\(current) days")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Best")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("\(viewModel.activity.bestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.primary)
                }
            }

            // Progress to next milestone
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Next milestone")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Day \(next)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("(\(remaining) to go)")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                // Progress bar with warm orange
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.Colors.cardBorder)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * viewModel.activity.progressToNext))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(Theme.Layout.cardPadding)
        .appleCard()
    }

    @ViewBuilder
    private var trendChartSection: some View {
        if !viewModel.historyValues.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Value Trend (30 Days)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(Theme.Colors.primary)
                        .font(.system(size: 14))
                }
                MiniChartView(
                    values: viewModel.historyValues,
                    targetValue: viewModel.historyTarget,
                    color: activityColor,
                    height: 120
                )
            }
            .padding(Theme.Layout.cardPadding)
            .appleCard()
        } else if viewModel.history != nil {
            VStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("No history yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("Complete this activity to see your trends.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .appleCard()
        }
    }

    @ViewBuilder
    private var calendarSection: some View {
        if let history = viewModel.history {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last 30 Days")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(Theme.Colors.primary)
                        .font(.system(size: 14))
                }

                calendarGrid(history)
                calendarTooltip
            }
            .padding(Theme.Layout.cardPadding)
            .appleCard()
        }
    }

    private func calendarGrid(_ history: ActivityHistoryResponse) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(height: 16)
            }

            ForEach(Array(history.entries.enumerated()), id: \.offset) { _, entry in
                calendarCell(entry)
            }
        }
    }

    private func calendarCell(_ entry: ActivityHistoryEntry) -> some View {
        let ratio: Double = entry.value > 0 ? 0.15 + 0.85 * min(1.0, entry.value / max(entry.target, 1)) : 0.05
        let cellColor = Theme.Colors.primary
        return RoundedRectangle(cornerRadius: 4)
            .fill(cellColor.opacity(ratio))
            .frame(height: 28)
            .overlay(
                Group {
                    if selectedDayEntry?.date == entry.date {
                        Text("\(Int(entry.value))/\(Int(entry.target))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(ratio > 0.5 ? .white : Theme.Colors.textPrimary)
                    }
                }
            )
            .onTapGesture {
                HapticManager.selection()
                selectedDayEntry = selectedDayEntry?.date == entry.date ? nil : entry
            }
    }

    @ViewBuilder
    private var calendarTooltip: some View {
        if let entry = selectedDayEntry {
            HStack(spacing: 8) {
                Text(entry.date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("\(Int(entry.value))/\(Int(entry.target)) \(viewModel.activity.unit)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.primary)
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.primary)
                        Text("\(entry.streak)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .padding(8)
            .background(Theme.Colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Stack Section

    private var stackSection: some View {
        Button {
            showStackPicker = true
        } label: {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(Theme.Colors.primary)
                Text("Stack With...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primary)
                Spacer()
                if viewModel.activity.stackId != nil {
                    Text("In stack")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.Colors.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Layout.cardPadding)
            .appleCard()
        }
    }

    private var stackPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Select an activity to stack with \(viewModel.activity.name)")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.top, 8)

                    ForEach(otherActivities.filter { $0.id != viewModel.activity.id }) { other in
                        Button {
                            Task {
                                do {
                                    let stack = try await APIService.shared.createStack(
                                        HabitStackCreate(name: "\(viewModel.activity.name) + \(other.name)")
                                    )
                                    _ = try await APIService.shared.addActivityToStack(
                                        stack.id,
                                        body: HabitStackAddActivity(activityId: viewModel.activity.id, order: 0)
                                    )
                                    _ = try await APIService.shared.addActivityToStack(
                                        stack.id,
                                        body: HabitStackAddActivity(activityId: other.id, order: 1)
                                    )
                                    HapticManager.success()
                                    showStackPicker = false
                                    await viewModel.refreshActivity()
                                } catch {
                                    viewModel.errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(other.emoji)
                                    .font(.title3)
                                Text(other.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "link")
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                            .padding(Theme.Layout.cardPadding)
                            .appleCard()
                        }
                    }
                }
                .padding(Theme.Layout.padding)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Stack With...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showStackPicker = false }
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
    }

    private var upgradeSection: some View {
        let points = authService.currentUser?.totalPoints ?? 0
        return Button {
            showUpgradeSheet = true
        } label: {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(points >= 1 ? Theme.Colors.accent : Theme.Colors.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade Target")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Current: \(Int(viewModel.activity.currentTarget)) \(viewModel.activity.unit)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .foregroundStyle(points >= 1 ? Theme.Colors.accent : Theme.Colors.textTertiary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: Theme.Icons.pointIcon)
                        .font(.caption)
                    Text("1")
                }
                .foregroundStyle(Theme.Colors.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.Colors.accent.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(Theme.Layout.cardPadding)
            .appleCard()
        }
        .disabled(points < 1)
    }

    private var dangerZoneSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.togglePause() }
            } label: {
                HStack {
                    Image(systemName: viewModel.activity.isPaused ? "play.circle.fill" : "pause.circle.fill")
                    Text(viewModel.activity.isPaused ? "Resume Activity" : "Pause Activity")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                }
                .padding(Theme.Layout.cardPadding)
                .foregroundStyle(Theme.Colors.primary)
                .background(Theme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                        .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                )
            }

            Button {
                HapticManager.warning()
                showDeleteConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Activity")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                }
                .padding(Theme.Layout.cardPadding)
                .background(Theme.Colors.danger.opacity(0.06))
                .foregroundStyle(Theme.Colors.danger)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                        .stroke(Theme.Colors.danger.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(Theme.Colors.danger)
        }
    }

    private func statItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.Colors.foxCream)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Upgrade Target Sheet

struct UpgradeTargetSheet: View {
    let activity: ActivityResponse
    let onUpgrade: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var targetText: String = ""
    @FocusState private var isFocused: Bool

    private var activityColor: Color {
        Color(hex: String(activity.colorHex.dropFirst()))
    }

    private var newTarget: Double? {
        guard let val = Double(targetText), val > activity.currentTarget else { return nil }
        return val
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current target display
                VStack(spacing: 8) {
                    Text(activity.emoji)
                        .font(.system(size: 40))

                    Text(activity.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    HStack(spacing: 6) {
                        Text("Current target:")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("\(Int(activity.currentTarget)) \(activity.unit.lowercased())")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(activityColor)
                    }
                }
                .padding(.top, 8)

                // Arrow
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                // New target input
                VStack(spacing: 10) {
                    Text("NEW TARGET")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)

                    HStack(spacing: 8) {
                        TextField("e.g. \(Int(activity.currentTarget + 5))", text: $targetText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(activityColor)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Theme.Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(newTarget != nil ? activityColor : Theme.Colors.cardBorder, lineWidth: newTarget != nil ? 2 : 1)
                    )
                    .padding(.horizontal, 40)

                    Text(activity.unit.lowercased())
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    if let val = Double(targetText), val <= activity.currentTarget {
                        Text("Must be higher than current target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.Colors.danger)
                    }
                }

                Spacer()

                // Cost + Upgrade button
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: Theme.Icons.pointIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Costs 1 point")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Button {
                        if let target = newTarget {
                            onUpgrade(target)
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18))
                            Text("Upgrade Target")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .background(
                        newTarget != nil
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: newTarget != nil ? Theme.Colors.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    .disabled(newTarget == nil)
                }
                .padding(.horizontal, Theme.Layout.padding)
                .padding(.bottom, 16)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Upgrade Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFocused = false }
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }
}
