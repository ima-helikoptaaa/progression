import SwiftUI

struct EditActivityView: View {
    let activity: ActivityResponse
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var emoji: String
    @State private var colorHex: String
    @State private var unit: String
    @State private var customUnitName: String
    @State private var identityId: UUID?
    @State private var cueTime: String
    @State private var cueLocation: String
    @State private var trackingMode: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var identities: [IdentityResponse] = []
    @State private var showAllIcons = false

    private let api = APIService.shared

    // Top 13 icons shown by default
    private let quickEmojis = [
        "\u{1F3C3}", "\u{1F4DA}", "\u{1F4AA}", "\u{1F9D8}", "\u{270D}\u{FE0F}", "\u{1F4A7}", "\u{1F9E0}",
        "\u{1F525}", "\u{1F6B4}", "\u{1F3CB}\u{FE0F}", "\u{1F634}", "\u{1F957}", "\u{1F48A}"
    ]

    private let allEmojis = [
        "\u{1F3C3}", "\u{1F4DA}", "\u{1F4AA}", "\u{1F9D8}", "\u{270D}\u{FE0F}", "\u{1F4A7}", "\u{1F9E0}",
        "\u{1F525}", "\u{1F6B4}", "\u{1F3CB}\u{FE0F}", "\u{1F634}", "\u{1F957}", "\u{1F48A}",
        "\u{2B50}", "\u{1F3B5}", "\u{1F331}", "\u{1F3AF}", "\u{1F4A1}", "\u{1F3CA}", "\u{1F9D7}",
        "\u{1F3A8}", "\u{1F4DD}", "\u{1F9F9}", "\u{1F415}", "\u{2615}", "\u{1F4B0}", "\u{1F3AE}",
        "\u{1F4F1}", "\u{1F6B6}", "\u{2764}\u{FE0F}", "\u{1F30D}", "\u{1F3B6}", "\u{1F4F8}", "\u{1F52C}"
    ]

    private let units = ["Minutes", "Reps", "Pages", "Miles", "Sets", "Custom"]
    private let predefinedUnits = ["Minutes", "Reps", "Pages", "Miles", "Sets"]

    init(activity: ActivityResponse, onSaved: @escaping () -> Void) {
        self.activity = activity
        self.onSaved = onSaved
        _name = State(initialValue: activity.name)
        _emoji = State(initialValue: activity.emoji)
        _colorHex = State(initialValue: activity.colorHex)
        _identityId = State(initialValue: activity.identityId)
        _cueTime = State(initialValue: activity.cueTime ?? "")
        _cueLocation = State(initialValue: activity.cueLocation ?? "")
        _trackingMode = State(initialValue: activity.trackingMode ?? "continuous")

        let predefined = ["Minutes", "Reps", "Pages", "Miles", "Sets"]
        if predefined.contains(activity.unit) {
            _unit = State(initialValue: activity.unit)
            _customUnitName = State(initialValue: "")
        } else {
            _unit = State(initialValue: "Custom")
            _customUnitName = State(initialValue: activity.unit)
        }
    }

    private var effectiveUnit: String {
        if unit == "Custom" {
            let trimmed = customUnitName.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "Units" : trimmed
        }
        return unit
    }

    private var previewColor: Color {
        Color(hex: String(colorHex.dropFirst()))
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

                        unitSection

                        trackingModeSection

                        if !identities.isEmpty {
                            identitySection
                        }

                        cueSection
                    }
                    .padding(.horizontal, Theme.Layout.padding)
                    .padding(.bottom, 100)
                }

                saveButton
            }
            .background(Theme.Colors.background)
            .navigationTitle("Edit Activity")
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
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(previewColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "Activity Name" : name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(name.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(Int(activity.currentTarget)) \(effectiveUnit)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(previewColor.opacity(0.2), lineWidth: 3.5)
                Circle()
                    .trim(from: 0, to: activity.completedToday ? 1.0 : 0.0)
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
            TextField("e.g., Morning Run", text: $name)
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
                .onChange(of: name) { _, newValue in
                    if newValue.count > 50 {
                        name = String(newValue.prefix(50))
                    }
                }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        let visibleIcons = showAllIcons ? allEmojis : quickEmojis

        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("ICON")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(visibleIcons, id: \.self) { opt in
                    Text(opt)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(
                            emoji == opt
                                ? previewColor.opacity(0.18)
                                : Theme.Colors.background
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(emoji == opt ? previewColor : Theme.Colors.cardBorder.opacity(0.5), lineWidth: emoji == opt ? 2 : 1)
                        )
                        .onTapGesture {
                            emoji = opt
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
                ForEach(Theme.Colors.activityColors, id: \.self) { hex in
                    let color = Color(hex: String(hex.dropFirst()))
                    let isSelected = colorHex == hex

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
                        .animation(Theme.Animation.bouncy, value: colorHex)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            colorHex = hex
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

    // MARK: - Unit

    private var unitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("UNIT")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(units, id: \.self) { u in
                        Text(u)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                unit == u
                                    ? previewColor
                                    : Theme.Colors.background
                            )
                            .foregroundStyle(unit == u ? .white : Theme.Colors.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(unit == u ? Color.clear : Theme.Colors.cardBorder, lineWidth: 1)
                            )
                            .onTapGesture {
                                unit = u
                                HapticManager.selection()
                            }
                    }
                }
            }

            if unit == "Custom" {
                TextField("Enter custom unit name", text: $customUnitName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Theme.Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                    )
                    .foregroundStyle(Theme.Colors.textPrimary)
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
        let isSelected = trackingMode == mode
        return Button {
            trackingMode = mode
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
        .animation(Theme.Animation.quick, value: trackingMode)
    }

    // MARK: - Identity

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("IDENTITY")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chipButton(label: "None", isSelected: identityId == nil) {
                        identityId = nil
                        HapticManager.selection()
                    }

                    ForEach(identities) { identity in
                        chipButton(
                            label: "\(identity.emoji) \(identity.name)",
                            isSelected: identityId == identity.id,
                            selectedColor: Color(hex: String(identity.colorHex.dropFirst()))
                        ) {
                            identityId = identity.id
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
                    TextField("Time", text: $cueTime)
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
                    TextField("Place", text: $cueLocation)
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

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 4) {
            Spacer()
            Button {
                save()
            } label: {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("Save Changes")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(
                name.trimmingCharacters(in: .whitespaces).isEmpty
                    ? AnyShapeStyle(Color.gray.opacity(0.3))
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, Theme.Layout.padding)

            if let error = errorMessage {
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

    private func save() {
        isSaving = true
        Task {
            do {
                let body = ActivityUpdate(
                    name: name.trimmingCharacters(in: .whitespaces),
                    emoji: emoji,
                    colorHex: colorHex,
                    unit: effectiveUnit,
                    identityId: identityId,
                    cueTime: cueTime.isEmpty ? nil : cueTime,
                    cueLocation: cueLocation.isEmpty ? nil : cueLocation,
                    trackingMode: trackingMode
                )
                _ = try await api.updateActivity(activity.id, body: body)
                HapticManager.success()
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}
