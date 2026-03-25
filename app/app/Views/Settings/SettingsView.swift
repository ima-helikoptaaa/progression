import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSignOutConfirm = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            List {
                // Profile card section
                Section {
                    if let user = authService.currentUser {
                        VStack(spacing: 14) {
                            // Profile card
                            ZStack {
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))

                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.25))
                                            .frame(width: 64, height: 64)
                                        Text("\u{1F98A}")
                                            .font(.system(size: 32))
                                    }

                                    if isEditingName {
                                        HStack {
                                            TextField("Display Name", text: $editedName)
                                                .textFieldStyle(.plain)
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(Theme.Colors.textPrimary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Theme.Colors.card)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                            Button {
                                                saveName()
                                            } label: {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(Theme.Colors.success)
                                            }

                                            Button {
                                                isEditingName = false
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white.opacity(0.7))
                                            }
                                        }
                                    } else {
                                        HStack(spacing: 6) {
                                            Text(user.displayName ?? "User")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Button {
                                                editedName = user.displayName ?? ""
                                                isEditingName = true
                                            } label: {
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.body)
                                                    .foregroundStyle(.white.opacity(0.7))
                                            }
                                        }
                                    }

                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(.vertical, 20)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                // Points section
                Section("Points") {
                    NavigationLink {
                        PointsView()
                    } label: {
                        HStack {
                            Image(systemName: Theme.Icons.pointIcon)
                                .foregroundStyle(Theme.Colors.primary)
                            Text("Points & History")
                            Spacer()
                            Text("\(authService.currentUser?.totalPoints ?? 0)")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.card)

                // How It Works
                Section("Learn") {
                    Button {
                        showOnboarding = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(Theme.Colors.primary)
                            Text("How It Works")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.card)

                // Notifications placeholder
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Daily Reminders")
                        Spacer()
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }
                .listRowBackground(Theme.Colors.card)

                // About section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Link(destination: URL(string: "https://apps.apple.com")!) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Theme.Colors.danger)
                            Text("Rate Progression")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
                .listRowBackground(Theme.Colors.card)

                // Sign out
                Section {
                    Button {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundStyle(Theme.Colors.danger)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Theme.Colors.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingReviewView()
            }
        }
    }

    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isEditingName = false
        HapticManager.success()
        Task {
            let _ = try? await APIService.shared.updateMe(UserUpdate(displayName: trimmed))
            await authService.refreshUser()
        }
    }
}

// Simple review version of onboarding (no "Get Started" action, just dismiss)
struct OnboardingReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String, description: String)] = [
        ("flame.fill", "Fibonacci Streaks", "Build momentum naturally",
         "Complete activities daily to build streaks. Hit Fibonacci milestones (1, 2, 3, 5, 8, 13, 21...) to earn points."),
        ("star.fill", "Earn & Spend Points", "Grow your routine",
         "Use earned points to add new activities or upgrade existing ones. Start with one free activity."),
        ("arrow.counterclockwise", "Gentle Forgiveness", "Miss a day? It's okay.",
         "Missing a day doesn't reset to zero. Your streak drops to the previous Fibonacci number, keeping most of your progress."),
    ]

    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.foxCream)
                                .frame(width: 120, height: 120)
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.Colors.primary)
                        }
                        VStack(spacing: 12) {
                            Text(pages[index].title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(pages[index].subtitle)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Theme.Colors.accent)
                            Text(pages[index].description)
                                .font(.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .background(Theme.Colors.background)
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
    }
}
