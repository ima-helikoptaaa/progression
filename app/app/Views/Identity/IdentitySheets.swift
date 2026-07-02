import SwiftUI

struct CreateIdentitySheet: View {
    let onCreate: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "\u{1F3AF}"
    @State private var colorHex = "#6C5CE7"

    private let emojis = ["\u{1F3AF}", "\u{1F4AA}", "\u{1F9D8}", "\u{1F3C3}", "\u{1F4DA}", "\u{1F525}", "\u{1F9E0}", "\u{1F331}", "\u{1F4A1}", "\u{1F3A8}", "\u{2764}\u{FE0F}", "\u{1F48A}"]
    private let colors = Theme.Colors.activityColors

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NAME")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)
                    TextField("e.g., Runner", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .medium))
                        .padding(14)
                        .background(Theme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.cardBorder, lineWidth: 1))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > 30 {
                                name = String(newValue.prefix(30))
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ICON")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                        ForEach(emojis, id: \.self) { e in
                            Text(e)
                                .font(.system(size: 22))
                                .frame(width: 40, height: 40)
                                .background(emoji == e ? Color(hex: String(colorHex.dropFirst())).opacity(0.18) : Theme.Colors.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(emoji == e ? Color(hex: String(colorHex.dropFirst())) : Theme.Colors.cardBorder.opacity(0.5), lineWidth: emoji == e ? 2 : 1))
                                .accessibilityLabel("Icon \(e)")
                                .accessibilityAddTraits(emoji == e ? [.isButton, .isSelected] : .isButton)
                                .onTapGesture {
                                    emoji = e
                                    HapticManager.selection()
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("COLOR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)
                    HStack(spacing: 0) {
                        ForEach(colors, id: \.self) { hex in
                            let color = Color(hex: String(hex.dropFirst()))
                            let isSelected = colorHex == hex
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("Color")
                                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                                .onTapGesture {
                                    colorHex = hex
                                    HapticManager.selection()
                                }
                        }
                    }
                }

                Spacer()

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onCreate(trimmed, emoji, colorHex)
                    dismiss()
                } label: {
                    Text("Create Identity")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(canSubmit ? AnyShapeStyle(LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.accent], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.gray.opacity(0.3)))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(!canSubmit)
            }
            .padding(Theme.Layout.padding)
            .background(Theme.Colors.background)
            .navigationTitle("New Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct EditIdentitySheet: View {
    let identity: IdentityResponse
    let onUpdate: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = ""
    @State private var colorHex = ""

    private let emojis = ["\u{1F3AF}", "\u{1F4AA}", "\u{1F9D8}", "\u{1F3C3}", "\u{1F4DA}", "\u{1F525}", "\u{1F9E0}", "\u{1F331}", "\u{1F4A1}", "\u{1F3A8}", "\u{2764}\u{FE0F}", "\u{1F48A}"]
    private let colors = Theme.Colors.activityColors

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NAME")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)
                    TextField("e.g., Runner", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .medium))
                        .padding(14)
                        .background(Theme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.cardBorder, lineWidth: 1))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > 30 {
                                name = String(newValue.prefix(30))
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ICON")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                        ForEach(emojis, id: \.self) { e in
                            Text(e)
                                .font(.system(size: 22))
                                .frame(width: 40, height: 40)
                                .background(emoji == e ? Color(hex: String(colorHex.dropFirst())).opacity(0.18) : Theme.Colors.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(emoji == e ? Color(hex: String(colorHex.dropFirst())) : Theme.Colors.cardBorder.opacity(0.5), lineWidth: emoji == e ? 2 : 1))
                                .accessibilityLabel("Icon \(e)")
                                .accessibilityAddTraits(emoji == e ? [.isButton, .isSelected] : .isButton)
                                .onTapGesture {
                                    emoji = e
                                    HapticManager.selection()
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("COLOR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .tracking(0.5)
                    HStack(spacing: 0) {
                        ForEach(colors, id: \.self) { hex in
                            let color = Color(hex: String(hex.dropFirst()))
                            let isSelected = colorHex == hex
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("Color")
                                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                                .onTapGesture {
                                    colorHex = hex
                                    HapticManager.selection()
                                }
                        }
                    }
                }

                Spacer()

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onUpdate(trimmed, emoji, colorHex)
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(canSubmit ? AnyShapeStyle(LinearGradient(colors: [Theme.Colors.primary, Theme.Colors.accent], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.gray.opacity(0.3)))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(!canSubmit)
            }
            .padding(Theme.Layout.padding)
            .background(Theme.Colors.background)
            .navigationTitle("Edit Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            name = identity.name
            emoji = identity.emoji
            colorHex = identity.colorHex
        }
    }
}
