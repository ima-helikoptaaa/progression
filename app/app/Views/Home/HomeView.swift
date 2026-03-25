import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AuthService.self) private var authService
    @Environment(AppState.self) private var appState
    @State private var showNewActivity = false
    @State private var selectedActivity: ActivityResponse?
    @State private var completingActivity: ActivityResponse?
    @State private var showStackCompletion: ActivityResponse?
    @State private var dropTargetId: UUID?
    @State private var showStackConfirm = false
    @State private var pendingStackSource: UUID?
    @State private var pendingStackTarget: UUID?
    @State private var showDeleteConfirm = false
    @State private var activityToDelete: ActivityResponse?

    var body: some View {
        NavigationStack {
            ZStack {
                // Warm cream background
                Theme.Colors.background
                    .ignoresSafeArea()

                List {
                    headerSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)

                    penaltyBanner
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)

                    if viewModel.groupByIdentity && !viewModel.identities.isEmpty {
                        groupedContent
                    } else {
                        standardContent
                    }

                    // Loading
                    if viewModel.isLoading {
                        Section {
                            ProgressView()
                                .tint(Theme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.loadActivities()
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showNewActivity = true
                            HapticManager.impact(.medium)
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary, Theme.Colors.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Theme.Colors.primary.opacity(0.35), radius: 10, y: 5)
                        }
                    }
                    .padding()
                }

                // Celebration overlay
                if let result = viewModel.completionResult {
                    CelebrationOverlay(isPresented: $viewModel.showCelebration, streak: result.newStreak)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
            .sheet(isPresented: $showNewActivity) {
                NewActivityView {
                    Task { await viewModel.loadActivities() }
                }
            }
            .sheet(item: $completingActivity) { activity in
                CompleteActivitySheet(activity: activity) { value, notes in
                    let result = await viewModel.completeActivity(activity, value: value, notes: notes)
                    if let points = result.totalPoints {
                        authService.updatePoints(points)
                    }
                    return result.success
                }
            }
            .sheet(item: $showStackCompletion) { activity in
                CompleteActivitySheet(activity: activity) { value, notes in
                    let result = await viewModel.completeActivity(activity, value: value, notes: notes)
                    if let points = result.totalPoints {
                        authService.updatePoints(points)
                    }
                    return result.success
                }
            }
            .task {
                // Check penalties first — this surfaces missed-day streak drops
                if let result = await viewModel.checkPenalties() {
                    if !result.penalties.isEmpty {
                        appState.setPenalties(result.penalties)
                    }
                    // Sync point total to AuthService
                    authService.updatePoints(result.totalPoints)
                }
                await viewModel.loadActivities()
            }
            .alert("Stack Activities", isPresented: $showStackConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingStackSource = nil
                    pendingStackTarget = nil
                }
                Button("Stack") {
                    if let src = pendingStackSource, let tgt = pendingStackTarget {
                        Task { await viewModel.createStackFromDrop(sourceId: src, targetId: tgt) }
                    }
                    pendingStackSource = nil
                    pendingStackTarget = nil
                }
            } message: {
                let srcName = viewModel.activities.first { $0.id == pendingStackSource }?.name ?? ""
                let tgtName = viewModel.activities.first { $0.id == pendingStackTarget }?.name ?? ""
                Text("Stack \"\(srcName)\" with \"\(tgtName)\"?")
            }
            .alert("Delete Activity", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {
                    activityToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let activity = activityToDelete {
                        Task { await viewModel.deleteActivity(activity) }
                    }
                    activityToDelete = nil
                }
            } message: {
                Text("This will permanently delete \"\(activityToDelete?.name ?? "")\" and all its history. This cannot be undone.")
            }
            .onChange(of: viewModel.nextStackActivityId) { _, newId in
                if let nextId = newId,
                   let activity = viewModel.activities.first(where: { $0.id == nextId }) {
                    viewModel.nextStackActivityId = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showStackCompletion = activity
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar: date + toggle + points
            HStack(alignment: .center) {
                Text(Date(), format: .dateTime.weekday(.abbreviated).day(.defaultDigits).month(.abbreviated))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer()

                // Group toggle
                if !viewModel.identities.isEmpty {
                    Button {
                        viewModel.groupByIdentity.toggle()
                        HapticManager.selection()
                    } label: {
                        Image(systemName: viewModel.groupByIdentity ? "person.3.fill" : "list.bullet")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.primary)
                            .frame(width: 32, height: 32)
                            .background(Theme.Colors.foxCream)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Theme.Colors.cardBorder, lineWidth: 1)
                            )
                    }
                }

                // Points badge
                HStack(spacing: 4) {
                    Image(systemName: Theme.Icons.pointIcon)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.warning)
                    Text("\(authService.currentUser?.totalPoints ?? 0)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.Colors.accent.opacity(0.25))
                .clipShape(Capsule())
            }
            .padding(.bottom, 20)

            // Greeting — large, wraps naturally with fox emoji inline
            (Text(viewModel.greeting)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
             + Text(" \u{1F98A}")
                .font(.system(size: 30))
            )
            .lineSpacing(2)
            .padding(.bottom, 6)

            // Motivational subtitle
            Text(viewModel.motivationalMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.bottom, 18)

            // TODAY'S PROGRESS card
            todaysProgressCard
        }
        .padding(Theme.Layout.padding)
    }

    // MARK: - Today's Progress Card

    private var todaysProgressCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY'S PROGRESS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(0.8)

                // Segmented bar
                HStack(spacing: 3) {
                    let total = viewModel.totalCount
                    let completed = viewModel.completedCount
                    if total > 0 {
                        ForEach(0..<total, id: \.self) { index in
                            Capsule()
                                .fill(index < completed ? Theme.Colors.primary : Color.white.opacity(0.2))
                                .frame(height: 5)
                                .animation(Theme.Animation.spring, value: completed)
                        }
                    }
                }

                Text("\(viewModel.completedCount) of \(viewModel.totalCount) completed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.primary)
            }

            Spacer()

            // Percentage
            Text("\(viewModel.totalCount > 0 ? Int(Double(viewModel.completedCount) / Double(viewModel.totalCount) * 100) : 0)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white) +
            Text("%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A0E00"))
        )
    }

    // MARK: - Penalty Banner

    @ViewBuilder
    private var penaltyBanner: some View {
        if !viewModel.penalties.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.Colors.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missed day penalty")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    ForEach(viewModel.penalties) { penalty in
                        Text("\(penalty.activityName): \(penalty.oldStreak) \u{2192} \(penalty.newStreak) days")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
                Button {
                    viewModel.penalties = []
                    appState.dismissPenalties()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Layout.cardPadding)
            .background(Theme.Colors.primary.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                    .stroke(Theme.Colors.primary.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
            .padding(.horizontal, Theme.Layout.padding)
        }
    }

    // MARK: - Standard content (no grouping)

    @ViewBuilder
    private var standardContent: some View {
        if !viewModel.pendingActivities.isEmpty {
            Section {
                HStack {
                    Text("TO DO")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .tracking(0.5)
                    Spacer()
                    Text("\(viewModel.pendingActivities.count) remaining")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: Theme.Layout.padding, bottom: 0, trailing: Theme.Layout.padding))

                ForEach(Array(viewModel.pendingActivities.enumerated()), id: \.element.id) { index, activity in
                    activityRow(activity, index: index, showConnector: shouldShowConnector(activity, in: viewModel.pendingActivities))
                }
            }
        }

        if !viewModel.completedActivities.isEmpty {
            Section {
                Text("COMPLETED")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.5)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: Theme.Layout.padding, bottom: 0, trailing: Theme.Layout.padding))

                ForEach(Array(viewModel.completedActivities.enumerated()), id: \.element.id) { index, activity in
                    activityRow(activity, index: index, showConnector: false)
                }
            }
        }

        if !viewModel.pausedActivities.isEmpty {
            Section {
                Text("PAUSED")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .tracking(0.5)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: Theme.Layout.padding, bottom: 0, trailing: Theme.Layout.padding))

                ForEach(viewModel.pausedActivities) { activity in
                    activityRow(activity, index: 0, showConnector: false)
                }
            }
        }
    }

    // MARK: - Grouped content (by identity)

    @ViewBuilder
    private var groupedContent: some View {
        ForEach(Array(viewModel.groupedActivities.enumerated()), id: \.offset) { _, group in
            Section {
                HStack(spacing: 6) {
                    if let identity = group.identity {
                        Text(identity.emoji)
                        Text(identity.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: String(identity.colorHex.dropFirst())))
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 12))
                        Text("General")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                ForEach(Array(group.activities.enumerated()), id: \.element.id) { index, activity in
                    activityRow(activity, index: index, showConnector: false)
                }
            }
        }
    }

    // MARK: - Activity Row

    private func activityRow(_ activity: ActivityResponse, index: Int, showConnector: Bool) -> some View {
        let identity = viewModel.identities.first { $0.id == activity.identityId }

        return ActivityCardView(
            activity: activity,
            identity: identity,
            onComplete: {
                completingActivity = activity
            },
            onTap: {
                selectedActivity = activity
            },
            onIncrement: {
                completingActivity = activity
            },
            showStackConnector: showConnector
        )
        .draggable(activity.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let sourceIdStr = items.first,
                  let sourceId = UUID(uuidString: sourceIdStr),
                  sourceId != activity.id else { return false }
            pendingStackSource = sourceId
            pendingStackTarget = activity.id
            showStackConfirm = true
            return true
        } isTargeted: { targeted in
            dropTargetId = targeted ? activity.id : (dropTargetId == activity.id ? nil : dropTargetId)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                .stroke(Theme.Colors.accent, lineWidth: dropTargetId == activity.id ? 2 : 0)
                .animation(Theme.Animation.quick, value: dropTargetId)
        )
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: Theme.Layout.padding, bottom: 4, trailing: Theme.Layout.padding))
        .listRowSeparator(.hidden)
        .animation(Theme.Animation.staggerDelay(index: index), value: viewModel.activities.count)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                completingActivity = activity
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(Theme.Colors.success)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                activityToDelete = activity
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                Task { await viewModel.togglePause(activity) }
            } label: {
                Label(activity.isPaused ? "Resume" : "Pause", systemImage: activity.isPaused ? "play" : "pause")
            }
            .tint(Theme.Colors.warning)
        }
    }

    private func shouldShowConnector(_ activity: ActivityResponse, in list: [ActivityResponse]) -> Bool {
        guard let stackId = activity.stackId else { return false }
        guard let index = list.firstIndex(where: { $0.id == activity.id }), index > 0 else { return false }
        return list[index - 1].stackId == stackId
    }
}

extension ActivityResponse: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ActivityResponse, rhs: ActivityResponse) -> Bool {
        lhs.id == rhs.id && lhs.currentStreak == rhs.currentStreak && lhs.completedToday == rhs.completedToday && lhs.valueDoneToday == rhs.valueDoneToday
    }
}
