import SwiftUI

struct NewActivityView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewActivityViewModel()
    @State private var identities: [IdentityResponse] = []
    @State private var showAllIcons = false
    let onCreated: () -> Void

    private var previewColor: Color {
        Color(hex: String(viewModel.colorHex.dropFirst()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        previewCard
                            .padding(.top, 8)

                        nameSection

                        iconSection

                        colorSection

                        targetAndUnitSection

                        trackingModeSection

                        if !identities.isEmpty {
                            identitySection
                        }

                        cueSection

                        costBadge
                    }
                    .padding(.horizontal, Theme.Layout.padding)
                    .padding(.bottom, 100)
                }

                createButton
            }
            .background(Theme.Colors.background)
            .navigationTitle("New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .task {
                do {
                    identities = try await APIService.shared.listIdentities()
                } catch {}
            }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        HStack(spacing: 14) {
            Text(viewModel.emoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(previewColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name.isEmpty ? "Activity Name" : viewModel.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(viewModel.name.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(Int(viewModel.baseTarget)) \(viewModel.effectiveUnit)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(previewColor.opacity(0.2), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: 0.0)
                    .stroke(previewColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 40, height: 40)
        }
        .padding(16)
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Theme.Colors.primary.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("NAME")
            TextField("e.g., Morning Run", text: $viewModel.name)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(Theme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
                .foregroundStyle(Theme.Colors.textPrimary)
                .onChange(of: viewModel.name) { _, newValue in
                    if newValue.count > 50 {
                        viewModel.name = String(newValue.prefix(50))
                    }
                }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        let visibleIcons = showAllIcons ? viewModel.allEmojis : viewModel.quickEmojis

        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ICON")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(visibleIcons, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(
                            viewModel.emoji == emoji
                                ? previewColor.opacity(0.18)
                                : Theme.Colors.background
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.emoji == emoji ? previewColor : Theme.Colors.cardBorder.opacity(0.5), lineWidth: viewModel.emoji == emoji ? 2 : 1)
                        )
                        .onTapGesture {
                            viewModel.emoji = emoji
                            HapticManager.selection()
                        }
                }

                if !showAllIcons {
                    Button {
                        withAnimation(Theme.Animation.spring) {
                            showAllIcons = true
                        }
                        HapticManager.selection()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.cardBorder.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Color

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("COLOR")

            HStack(spacing: 0) {
                ForEach(viewModel.colorOptions, id: \.self) { hex in
                    let color = Color(hex: String(hex.dropFirst()))
                    let isSelected = viewModel.colorHex == hex

                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.textPrimary.opacity(0.25), lineWidth: isSelected ? 2 : 0)
                                .padding(-1)
                        )
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(Theme.Animation.bouncy, value: viewModel.colorHex)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            viewModel.colorHex = hex
                            HapticManager.selection()
                        }
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Target + Unit

    private var targetAndUnitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("DAILY TARGET")
                HStack(spacing: 16) {
                    HStack(spacing: 0) {
                        Button {
                            if viewModel.baseTarget > 1 { viewModel.baseTarget -= 1 }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(viewModel.baseTarget > 1 ? Theme.Colors.textSecondary : Theme.Colors.textTertiary.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.baseTarget <= 1)

                        Text("\(Int(viewModel.baseTarget))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(previewColor)
                            .frame(minWidth: 48)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.2), value: viewModel.baseTarget)

                        Button {
                            if viewModel.baseTarget < 999 { viewModel.baseTarget += 1 }
                            HapticManager.selection()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(previewColor)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Text(viewModel.effectiveUnit)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(previewColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Divider().foregroundStyle(Theme.Colors.cardBorder)

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("UNIT")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.units, id: \.self) { unit in
                            Text(unit)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.unit == unit
                                        ? previewColor
                                        : Theme.Colors.background
                                )
                                .foregroundStyle(
                                    viewModel.unit == unit ? .white : Theme.Colors.textSecondary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(viewModel.unit == unit ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                                )
                                .onTapGesture {
                                    viewModel.unit = unit
                                    HapticManager.selection()
                                }
                        }
                    }
                }

                if viewModel.unit == "Custom" {
                    TextField("Enter custom unit name", text: $viewModel.customUnitName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Theme.Colors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                        )
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
        }
        .padding(16)
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Tracking Mode

    private var trackingModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TRACKING STYLE")
            HStack(spacing: 0) {
                trackingModeOption(
                    icon: "circle.dotted",
                    title: "Continuous",
                    subtitle: "Slider & ring",
                    mode: "continuous"
                )
                trackingModeOption(
                    icon: "number",
                    title: "Discrete",
                    subtitle: "Tap to count",
                    mode: "discrete"
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
            )
        }
    }

    private func trackingModeOption(icon: String, title: String, subtitle: String, mode: String) -> some View {
        let isSelected = viewModel.trackingMode == mode
        return Button {
            viewModel.trackingMode = mode
            HapticManager.selection()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : Theme.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? previewColor : Theme.Colors.card)
            .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.quick, value: viewModel.trackingMode)
    }

    // MARK: - Identity

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("IDENTITY")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chipButton(label: "None", isSelected: viewModel.identityId == nil) {
                        viewModel.identityId = nil
                        HapticManager.selection()
                    }

                    ForEach(identities) { identity in
                        chipButton(
                            label: "\(identity.emoji) \(identity.name)",
                            isSelected: viewModel.identityId == identity.id,
                            selectedColor: Color(hex: String(identity.colorHex.dropFirst()))
                        ) {
                            viewModel.identityId = identity.id
                            HapticManager.selection()
                        }
                    }
                }
            }
        }
    }

    private func chipButton(label: String, isSelected: Bool, selectedColor: Color? = nil, action: @escaping () -> Void) -> some View {
        let bg = isSelected ? (selectedColor ?? Theme.Colors.primary) : Theme.Colors.card
        return Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bg)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cue

    private var cueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WHEN & WHERE")
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(previewColor)
                        .font(.system(size: 14))
                    TextField("Time", text: $viewModel.cueTime)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(12)
                .background(Theme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )

                HStack(spacing: 8) {
                    Image(systemName: "location")
                        .foregroundStyle(previewColor)
                        .font(.system(size: 14))
                    TextField("Place", text: $viewModel.cueLocation)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(12)
                .background(Theme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Cost Badge

    private var costBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: Theme.Icons.pointIcon)
                .foregroundStyle(Theme.Colors.accent)
                .font(.system(size: 14))
            Text("Free!")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.success)
            Spacer()
            Text("1 FREE POINT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.Colors.primary.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Theme.Colors.success.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.success.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Create Button

    private var createButton: some View {
        VStack(spacing: 4) {
            Spacer()
            Button {
                let points = authService.currentUser?.totalPoints ?? 0
                Task {
                    let success = await viewModel.createActivity(userPoints: points, existingCount: 0)
                    if success {
                        onCreated()
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isCreating {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Create Activity")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(
                viewModel.isValid
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
            .shadow(color: viewModel.isValid ? Theme.Colors.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .disabled(!viewModel.isValid || viewModel.isCreating)
            .padding(.horizontal, Theme.Layout.padding)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.danger)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Theme.Colors.textTertiary)
            .tracking(0.5)
    }
}
