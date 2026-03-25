import SwiftUI

struct PointsView: View {
    @State private var viewModel = PointsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let balance = viewModel.balance {
                    // Hero section with fox avatar
                    VStack(spacing: 16) {
                        // Fox avatar circle
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary, Theme.Colors.accent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                            Text("\u{1F98A}")
                                .font(.system(size: 38))
                        }

                        // Large point display
                        VStack(spacing: 6) {
                            AnimatedCounterLarge(
                                value: balance.totalPoints,
                                color: Theme.Colors.textPrimary
                            )

                            HStack(spacing: 4) {
                                Text("+\(formattedNumber(balance.lifetimePoints))")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.Colors.success)
                                Text("/")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                Text("\(formattedNumber(balance.spentPoints))")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.Colors.danger)
                            }

                            Text("Available Points")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        // Earned / Spent counters
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.Colors.success)
                                    Text("Earned")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                AnimatedCounter(
                                    value: balance.lifetimePoints,
                                    font: .system(size: 20, weight: .bold, design: .rounded),
                                    color: Theme.Colors.success
                                )
                            }
                            .frame(maxWidth: .infinity)

                            // Divider
                            Rectangle()
                                .fill(Theme.Colors.cardBorder)
                                .frame(width: 1, height: 40)

                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.Colors.danger)
                                    Text("Spent")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.Colors.textTertiary)
                                }
                                AnimatedCounter(
                                    value: balance.spentPoints,
                                    font: .system(size: 20, weight: .bold, design: .rounded),
                                    color: Theme.Colors.danger
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 12)
                        .appleCard()
                    }
                    .padding(.vertical, 8)

                    // Transaction History section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transaction History")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.Colors.primary.opacity(0.5))
                        }

                        if balance.transactions.isEmpty {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.Colors.primary.opacity(0.08))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "clock")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                                Text("No transactions yet")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                Text("Complete activities to earn points!")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }

                        let grouped = groupedTransactions(balance.transactions)
                        ForEach(Array(grouped.keys.sorted().reversed()), id: \.self) { dateKey in
                            if let transactions = grouped[dateKey] {
                                // Date header
                                Text(dateKey)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                    .padding(.top, 4)

                                ForEach(transactions) { tx in
                                    HStack(spacing: 10) {
                                        // Transaction type icon with warm tint
                                        ZStack {
                                            Circle()
                                                .fill(transactionIconColor(tx).opacity(0.12))
                                                .frame(width: 34, height: 34)
                                            Image(systemName: transactionIcon(tx))
                                                .font(.system(size: 13))
                                                .foregroundStyle(transactionIconColor(tx))
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(tx.description)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Theme.Colors.textPrimary)
                                                .lineLimit(1)
                                            Text(tx.transactionType.capitalized)
                                                .font(.system(size: 11))
                                                .foregroundStyle(Theme.Colors.textTertiary)
                                        }

                                        Spacer()

                                        Text(tx.amount > 0 ? "+\(tx.amount)" : "\(tx.amount)")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(tx.amount > 0 ? Theme.Colors.success : Theme.Colors.danger)
                                    }
                                    .padding(.vertical, 4)

                                    if tx.id != transactions.last?.id {
                                        Divider()
                                            .background(Theme.Colors.cardBorder)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Theme.Layout.cardPadding)
                    .appleCard()

                    // Milestone rewards teaser
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.accent.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.Colors.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Milestone Rewards")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text("Unlock rewards as you reach new milestones!")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Spacer()

                            Text("Soon")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Colors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        // Preview milestone items
                        HStack(spacing: 12) {
                            milestonePill(emoji: "\u{1F31F}", label: "1K pts")
                            milestonePill(emoji: "\u{1F525}", label: "5K pts")
                            milestonePill(emoji: "\u{1F451}", label: "10K pts")
                            milestonePill(emoji: "\u{1F48E}", label: "25K pts")
                        }
                    }
                    .padding(Theme.Layout.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                            .fill(Theme.Colors.accent.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                                    .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 1)
                            )
                    )

                } else if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.08))
                                .frame(width: 64, height: 64)
                            Text("\u{1F98A}")
                                .font(.system(size: 30))
                        }
                        ProgressView()
                            .tint(Theme.Colors.primary)
                    }
                    .padding(.top, 60)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.08))
                                .frame(width: 56, height: 56)
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.loadPoints() }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.card)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.primary)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 60)
                }
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background)
        .task {
            await viewModel.loadPoints()
        }
    }

    // MARK: - Milestone Pill

    private func milestonePill(emoji: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 20))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.card)
                .shadow(color: Theme.Colors.primary.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Helpers

    private func formattedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func transactionIcon(_ tx: PointTransactionResponse) -> String {
        switch tx.transactionType {
        case "milestone": return "star.fill"
        case "upgrade": return "arrow.up.circle.fill"
        case "welcome": return "gift.fill"
        case "create": return "plus.circle.fill"
        default: return "circle.fill"
        }
    }

    private func transactionIconColor(_ tx: PointTransactionResponse) -> Color {
        switch tx.transactionType {
        case "milestone": return Theme.Colors.warning
        case "upgrade": return Theme.Colors.primary
        case "welcome": return Theme.Colors.success
        case "create": return Theme.Colors.accent
        default: return Theme.Colors.textTertiary
        }
    }

    private func groupedTransactions(_ transactions: [PointTransactionResponse]) -> [String: [PointTransactionResponse]] {
        var grouped: [String: [PointTransactionResponse]] = [:]
        for tx in transactions {
            let dateKey = String(tx.createdAt.prefix(10))
            grouped[dateKey, default: []].append(tx)
        }
        return grouped
    }
}
