import SwiftUI

struct IdentityManagementView: View {
    @State private var viewModel = IdentityViewModel()
    @State private var showCreateSheet = false
    @State private var editingIdentity: IdentityResponse?
    @State private var showDeleteConfirm = false
    @State private var identityToDelete: IdentityResponse?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info
                HStack(spacing: 10) {
                    Text("\u{1F98A}")
                        .font(.system(size: 20))
                    Text("Identities represent who you want to become. Max 3.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(Theme.Layout.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.foxCream)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                )

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.Colors.primary)
                        .padding(.top, 40)
                } else {
                    ForEach(viewModel.identities) { identity in
                        identityCard(identity)
                    }

                    if viewModel.identities.count < 3 {
                        Button {
                            showCreateSheet = true
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
                            .shadow(color: Theme.Colors.primary.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                }
            }
            .padding(Theme.Layout.padding)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Identities")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCreateSheet) {
            CreateIdentitySheet { name, emoji, colorHex in
                Task {
                    _ = await viewModel.createIdentity(name: name, emoji: emoji, colorHex: colorHex)
                }
            }
        }
        .sheet(item: $editingIdentity) { identity in
            EditIdentitySheet(identity: identity) { name, emoji, colorHex in
                Task {
                    await viewModel.updateIdentity(identity.id, name: name, emoji: emoji, colorHex: colorHex)
                }
            }
        }
        .alert("Delete Identity", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let identity = identityToDelete {
                    Task { await viewModel.deleteIdentity(identity.id) }
                }
            }
        } message: {
            Text("This will remove the identity and unlink all its activities. The activities themselves will not be deleted.")
        }
        .task {
            await viewModel.loadIdentities()
        }
    }

    private func identityCard(_ identity: IdentityResponse) -> some View {
        HStack(spacing: 14) {
            Text(identity.emoji)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(Color(hex: String(identity.colorHex.dropFirst())).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(identity.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("I am \(identity.name.lowercased())")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            Button {
                editingIdentity = identity
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.primary.opacity(0.6))
            }

            Button {
                identityToDelete = identity
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.danger.opacity(0.6))
            }
        }
        .padding(Theme.Layout.cardPadding)
        .appleCard()
    }
}

// MARK: - Create Sheet

struct CreateIdentitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "\u{1F3AF}"
    @State private var colorHex = "#FF6B35"
    let onCreate: (String, String, String) -> Void

    private let emojiOptions = ["\u{1F3AF}", "\u{1F4AA}", "\u{1F9E0}", "\u{1F331}", "\u{1F525}", "\u{1F3C3}", "\u{1F4DA}", "\u{270D}\u{FE0F}", "\u{1F9D8}", "\u{1F3A8}", "\u{1F4A1}", "\u{1F31F}"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview
                    HStack(spacing: 10) {
                        Text(emoji)
                            .font(.system(size: 40))
                        Text(name.isEmpty ? "Identity Name" : "I am \(name.lowercased())")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(name.isEmpty ? Theme.Colors.textTertiary : Theme.Colors.textPrimary)
                    }
                    .padding(.top, 16)

                    // Emoji
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { opt in
                                Text(opt)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(emoji == opt ? Theme.Colors.primary.opacity(0.2) : Theme.Colors.card)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(emoji == opt ? Theme.Colors.primary : Theme.Colors.cardBorder, lineWidth: emoji == opt ? 2 : 1)
                                    )
                                    .onTapGesture {
                                        emoji = opt
                                        HapticManager.selection()
                                    }
                            }
                        }
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Identity Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        TextField("e.g., A Runner, A Reader", text: $name)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Theme.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                            )
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .onChange(of: name) { _, newValue in
                                if newValue.count > 30 {
                                    name = String(newValue.prefix(30))
                                }
                            }
                        if name.trimmingCharacters(in: .whitespaces).isEmpty && !name.isEmpty {
                            Text("Enter a valid name to create")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }

                    // Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(Theme.Colors.activityColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: String(hex.dropFirst())))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Theme.Colors.textPrimary, lineWidth: colorHex == hex ? 2.5 : 0)
                                            .padding(1)
                                    )
                                    .onTapGesture {
                                        colorHex = hex
                                        HapticManager.selection()
                                    }
                            }
                        }
                    }
                }
                .padding(Theme.Layout.padding)
            }
            .background(Theme.Colors.background)
            .navigationTitle("New Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, emoji, colorHex)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.textTertiary : Theme.Colors.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
}

// MARK: - Edit Sheet

struct EditIdentitySheet: View {
    let identity: IdentityResponse
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var emoji: String
    @State private var colorHex: String
    let onSave: (String?, String?, String?) -> Void

    private let emojiOptions = ["\u{1F3AF}", "\u{1F4AA}", "\u{1F9E0}", "\u{1F331}", "\u{1F525}", "\u{1F3C3}", "\u{1F4DA}", "\u{270D}\u{FE0F}", "\u{1F9D8}", "\u{1F3A8}", "\u{1F4A1}", "\u{1F31F}"]

    init(identity: IdentityResponse, onSave: @escaping (String?, String?, String?) -> Void) {
        self.identity = identity
        self.onSave = onSave
        _name = State(initialValue: identity.name)
        _emoji = State(initialValue: identity.emoji)
        _colorHex = State(initialValue: identity.colorHex)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { opt in
                                Text(opt)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(emoji == opt ? Theme.Colors.primary.opacity(0.2) : Theme.Colors.card)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(emoji == opt ? Theme.Colors.primary : Theme.Colors.cardBorder, lineWidth: emoji == opt ? 2 : 1)
                                    )
                                    .onTapGesture {
                                        emoji = opt
                                        HapticManager.selection()
                                    }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Identity Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        TextField("Identity name", text: $name)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Theme.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                            )
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(Theme.Colors.activityColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: String(hex.dropFirst())))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Theme.Colors.textPrimary, lineWidth: colorHex == hex ? 2.5 : 0)
                                            .padding(1)
                                    )
                                    .onTapGesture {
                                        colorHex = hex
                                        HapticManager.selection()
                                    }
                            }
                        }
                    }
                }
                .padding(Theme.Layout.padding)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Edit Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, emoji, colorHex)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.Colors.textTertiary : Theme.Colors.primary)
                }
            }
        }
    }
}

extension IdentityResponse: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: IdentityResponse, rhs: IdentityResponse) -> Bool {
        lhs.id == rhs.id
    }
}
