import SwiftUI

/// Create or edit the local account: name, handle, avatar and bio.
struct AccountSetupView: View {
    @Environment(ProfileStore.self) private var profile
    @Environment(\.dismiss) private var dismiss

    /// When true, this is first-time creation and offers a "skip" path.
    var isCreating: Bool = false

    @State private var displayName = ""
    @State private var handle = ""
    @State private var bio = ""
    @State private var colorIndex = 0
    @State private var emoji = ""

    private let emojiChoices = [""] + EmojiCatalog.all

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var previewText: String {
        if !emoji.isEmpty { return emoji }
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "🙂" : result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AvatarView(
                        colors: Theme.deckGradients[colorIndex % Theme.deckGradients.count],
                        text: previewText,
                        size: 96
                    )
                    .padding(.top, 8)

                    VStack(spacing: 14) {
                        field(title: "Name", text: $displayName, placeholder: "Your name")
                        field(title: "Username", text: $handle, placeholder: "@handle", autocap: false)
                        field(title: "Bio", text: $bio, placeholder: "Say something about your learning", axis: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Avatar color")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Theme.deckGradients.indices, id: \.self) { index in
                                    Circle()
                                        .fill(LinearGradient(colors: Theme.deckGradients[index], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle().strokeBorder(Theme.primary, lineWidth: colorIndex == index ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3)) { colorIndex = index }
                                            Haptics.tap()
                                        }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Emoji (optional)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(emojiChoices, id: \.self) { choice in
                                    Text(choice.isEmpty ? "Aa" : choice)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Color(.secondarySystemGroupedBackground),
                                            in: Circle()
                                        )
                                        .overlay(Circle().strokeBorder(Theme.primary, lineWidth: emoji == choice ? 2.5 : 0))
                                        .onTapGesture {
                                            emoji = choice
                                            Haptics.tap()
                                        }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    PrimaryButton(title: isCreating ? "Create account" : "Save", systemImage: "checkmark") {
                        profile.save(displayName: displayName, handle: handle, bio: bio, colorIndex: colorIndex, emoji: emoji)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .auroraBackground()
            .navigationTitle(isCreating ? "Create your account" : "Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isCreating {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") {
                            profile.save(displayName: "Guest", handle: "@guest", bio: "", colorIndex: 0, emoji: "🙂")
                            dismiss()
                        }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .onAppear(perform: populate)
        }
        .interactiveDismissDisabled(isCreating)
    }

    private func populate() {
        guard profile.hasAccount else { return }
        displayName = profile.displayName
        handle = profile.handle
        bio = profile.bio
        colorIndex = profile.avatarColorIndex
        emoji = profile.avatarEmoji
    }

    private func field(title: LocalizedStringKey, text: Binding<String>, placeholder: LocalizedStringKey, autocap: Bool = true, axis: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Group {
                if axis {
                    TextField(placeholder, text: text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textInputAutocapitalization(autocap ? .sentences : .never)
            .autocorrectionDisabled(!autocap)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
