import SwiftUI

struct IdentityTabView: View {
    @State private var viewModel = IdentityTabViewModel()
    @State private var selectedActivityId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.Colors.primary)
                } else if viewModel.identities.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.identities) { identity in
                                identitySection(identity)
                            }

                            if viewModel.identities.count < 3 {
                                addButton
                            }
                        }
                        .padding(Theme.Layout.padding)
                    }
                    .background(Theme.Colors.background)
                }
            }
            .navigationTitle("Identity")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { activityId in
                Text("Activity \(activityId)")
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateIdentitySheet { name, emoji, colorHex in
                    Task {
                        _ = await viewModel.createIdentity(name: name, emoji: emoji, colorHex: colorHex)
                    }
                }
            }
            .sheet(item: $viewModel.editingIdentity) { identity in
                EditIdentitySheet(identity: identity) { name, emoji, colorHex in
                    Task {
                        await viewModel.updateIdentity(identity.id, name: name, emoji: emoji, colorHex: colorHex)
                    }
                }
            }
            .alert("Delete Identity", isPresented: $viewModel.showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let identity = viewModel.identityToDelete {
                        Task { await viewModel.deleteIdentity(identity.id) }
                    }
                }
            } message: {
                Text("This will remove the identity and unlink all its activities. The activities themselves will not be deleted.")
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.foxCream)
                    .frame(width: 100, height: 100)
                Text("\u{1F98A}")
                    .font(.system(size: 44))
            }

            Text("Define who you want to become")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Create up to 3 identities and link your activities to them. Your fox guide is ready to help!")
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                viewModel.showCreateSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Identity")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.Colors.primary)
                .clipShape(Capsule())
                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Spacer()
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Identity Section

    private func identitySection(_ identity: IdentityResponse) -> some View {
        let color = Color(hex: String(identity.colorHex.dropFirst()))
        let stats = viewModel.statsMap[identity.id]

        return VStack(spacing: 12) {
            // Header card
            HStack(spacing: 14) {
                Text(identity.emoji)
                    .font(.system(size: 36))
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(identity.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("I am \(identity.name.lowercased())")
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                }

                Spacer()

                Button {
                    viewModel.editingIdentity = identity
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.primary.opacity(0.6))
                }

                Button {
                    viewModel.identityToDelete = identity
                    viewModel.showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.Colors.danger.opacity(0.6))
                }
            }
            .padding(Theme.Layout.cardPadding)
            .appleCard()

            // Stats row
            if let stats {
                HStack(spacing: 0) {
                    statCell(value: "\(stats.totalCompletions)", label: "Completions")
                    Divider().frame(height: 30).overlay(Theme.Colors.cardBorder)
                    statCell(value: "\(stats.bestStreak)", label: "Best Streak")
                    Divider().frame(height: 30).overlay(Theme.Colors.cardBorder)
                    statCell(value: "\(Int(stats.weeklyCompletionRate * 100))%", label: "Weekly Rate")
                }
                .padding(.vertical, 12)
                .appleCard()
            }

            // Linked activities
            if let stats, !stats.activityStats.isEmpty {
                VStack(spacing: 2) {
                    ForEach(stats.activityStats) { actStat in
                        HStack(spacing: 10) {
                            Text(actStat.emoji)
                                .font(.system(size: 18))

                            Text(actStat.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Spacer()

                            if actStat.currentStreak > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.Colors.warning)
                                    Text("\(actStat.currentStreak)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.Colors.warning)
                                }
                            }

                            Image(systemName: actStat.completedToday ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundStyle(actStat.completedToday ? Theme.Colors.success : Theme.Colors.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.card)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
                .shadow(color: Theme.Colors.primary.opacity(0.06), radius: 4, x: 0, y: 1)
            } else if stats == nil {
                ProgressView()
                    .tint(color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            viewModel.showCreateSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Identity")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.Colors.card)
            .foregroundStyle(Theme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.primary.opacity(0.06), radius: 4, x: 0, y: 1)
        }
    }
}
