import SwiftUI

struct StatsView: View {
    @State private var viewModel = StatsViewModel()
    @State private var selectedHeatmapEntry: HeatmapEntry?
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let overview = viewModel.overview {
                        // Summary cards with animated counters
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            animatedStatCard(
                                "Completions",
                                overview.totalCompletions,
                                "checkmark.circle.fill",
                                Theme.Colors.primary
                            )
                            animatedStatCard(
                                "Best Streak",
                                overview.bestStreak,
                                "flame.fill",
                                Theme.Colors.warning
                            )
                            animatedStatCard(
                                "Points Earned",
                                overview.totalPointsEarned,
                                Theme.Icons.pointIcon,
                                Theme.Colors.accent
                            )
                            animatedStatCard(
                                "Activities",
                                overview.activeActivities,
                                "square.grid.2x2.fill",
                                Theme.Colors.primaryLight
                            )
                        }

                        // Weekly comparison
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("This Week")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Colors.primary.opacity(0.6))
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    AnimatedCounter(
                                        value: overview.currentWeekCompletions,
                                        font: .system(size: 28, weight: .bold, design: .rounded),
                                        color: Theme.Colors.primary
                                    )
                                    Text("This week")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }

                                VStack(alignment: .leading) {
                                    Text("\(overview.previousWeekCompletions)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                    Text("Last week")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }

                                Spacer()

                                let diff = overview.currentWeekCompletions - overview.previousWeekCompletions
                                if diff != 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: diff > 0 ? "arrow.up.right" : "arrow.down.right")
                                        Text("\(abs(diff))")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(diff > 0 ? Theme.Colors.success : Theme.Colors.danger)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        (diff > 0 ? Theme.Colors.success : Theme.Colors.danger).opacity(0.1)
                                    )
                                    .clipShape(Capsule())
                                }
                            }

                            // Weekly completion rate
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Completion Rate")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                    Spacer()
                                    Text("\(Int(viewModel.weeklyCompletionRate * 100))%")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Theme.Colors.primary.opacity(0.12))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Theme.Colors.primary, Theme.Colors.accent],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * viewModel.weeklyCompletionRate, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                        .padding(Theme.Layout.cardPadding)
                        .appleCard()

                        // Streak insight
                        if let insight = viewModel.streakInsight {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.Colors.accent.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Colors.warning)
                                }
                                Text(insight)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            .padding(Theme.Layout.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                                    .fill(Theme.Colors.accent.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                                            .stroke(Theme.Colors.accent.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    // Heatmap
                    if let heatmap = viewModel.heatmap {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Activity Heatmap")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Text("\u{1F525}")
                                    .font(.system(size: 14))
                            }

                            // Day labels + grid
                            HStack(alignment: .top, spacing: 4) {
                                // Day labels
                                VStack(spacing: 3) {
                                    Text("").frame(height: 16) // spacer for month row
                                    Text("M").font(.system(size: 9)).foregroundStyle(Theme.Colors.textTertiary).frame(height: 16)
                                    Text("").frame(height: 16)
                                    Text("W").font(.system(size: 9)).foregroundStyle(Theme.Colors.textTertiary).frame(height: 16)
                                    Text("").frame(height: 16)
                                    Text("F").font(.system(size: 9)).foregroundStyle(Theme.Colors.textTertiary).frame(height: 16)
                                    Text("").frame(height: 16)
                                }

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 13), spacing: 3) {
                                    ForEach(heatmap.entries) { entry in
                                        let fillOpacity = max(0.08, (entry.intensity ?? entry.ratio) * 0.9)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Theme.Colors.primary.opacity(fillOpacity))
                                            .frame(height: 16)
                                            .onTapGesture {
                                                HapticManager.selection()
                                                selectedHeatmapEntry = selectedHeatmapEntry?.id == entry.id ? nil : entry
                                            }
                                    }
                                }
                            }

                            // Color legend - warm orange gradient
                            HStack(spacing: 4) {
                                Text("Less")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                ForEach([0.08, 0.25, 0.5, 0.75, 0.9], id: \.self) { opacity in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.Colors.primary.opacity(opacity))
                                        .frame(width: 12, height: 12)
                                }
                                Text("More")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            // Tooltip
                            if let entry = selectedHeatmapEntry {
                                HStack(spacing: 6) {
                                    Text(entry.date)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                    Text("\(entry.count) completions")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Theme.Colors.primary)
                                    if let totalComp = entry.totalCompletions, totalComp > entry.count {
                                        Text("(\(totalComp) total)")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Theme.Colors.accent)
                                    }
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.Colors.card)
                                        .shadow(color: Theme.Colors.primary.opacity(0.08), radius: 4, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                        .padding(Theme.Layout.cardPadding)
                        .appleCard()
                    }

                    // Activity breakdown
                    if !viewModel.activities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Activity Breakdown")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.Colors.primary.opacity(0.5))
                            }

                            ForEach(viewModel.activities.filter { !$0.isPaused }) { activity in
                                NavigationLink(value: activity) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Theme.Colors.primary.opacity(0.08))
                                                .frame(width: 38, height: 38)
                                            Text(activity.emoji)
                                                .font(.title3)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(activity.name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(Theme.Colors.textPrimary)
                                            HStack(spacing: 8) {
                                                HStack(spacing: 3) {
                                                    Image(systemName: "flame.fill")
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(Theme.Colors.warning)
                                                    Text("\(activity.currentStreak)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundStyle(Theme.Colors.textSecondary)
                                                }
                                                HStack(spacing: 3) {
                                                    Image(systemName: "trophy.fill")
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(Theme.Colors.accent)
                                                    Text("\(activity.bestStreak)")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundStyle(Theme.Colors.textSecondary)
                                                }
                                            }
                                        }

                                        Spacer()

                                        // Mini progress to next milestone
                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text("Day \(activity.nextMilestone)")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(Theme.Colors.accent)
                                            ProgressView(value: activity.progressToNext)
                                                .tint(Theme.Colors.primary)
                                                .frame(width: 50)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(Theme.Colors.textTertiary)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)

                                if activity.id != viewModel.activities.filter({ !$0.isPaused }).last?.id {
                                    Divider()
                                        .background(Theme.Colors.cardBorder)
                                }
                            }
                        }
                        .padding(Theme.Layout.cardPadding)
                        .appleCard()
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.Colors.primary)
                            .padding(.top, 40)
                    } else if viewModel.overview == nil && viewModel.errorMessage != nil {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.primary.opacity(0.08))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                            Text(viewModel.errorMessage ?? "Failed to load stats")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await viewModel.loadStats() }
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.card)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.Colors.primary)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 40)
                    } else if viewModel.overview != nil && viewModel.overview?.totalCompletions == 0 {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.primary.opacity(0.08))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                            Text("No activity data yet")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text("Complete some activities and your stats will appear here.")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(Theme.Layout.padding)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Stats / Analytics")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ActivityResponse.self) { activity in
                ActivityDetailView(activity: activity)
            }
            .task {
                await viewModel.loadStats()
            }
        }
    }

    private func animatedStatCard(_ title: String, _ value: Int, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }
            AnimatedCounter(
                value: value,
                font: .system(size: 24, weight: .bold, design: .rounded),
                color: Theme.Colors.textPrimary
            )
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .appleCard()
    }
}
