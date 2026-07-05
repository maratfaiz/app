import SwiftUI
import SwiftData

/// Create or edit a deck (title, description, languages, color and emoji).
struct DeckFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil = creating a new deck.
    let deck: Deck?

    @State private var title = ""
    @State private var desc = ""
    @State private var sourceLang = "en-US"
    @State private var targetLang = "ru-RU"
    @State private var colorIndex = 0
    @State private var emoji = ""

    private var isEditing: Bool { deck != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let emojiColumns = [GridItem(.adaptive(minimum: 44), spacing: 8)]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    previewCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Deck") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $desc, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Theme.deckGradients.indices, id: \.self) { index in
                                Circle()
                                    .fill(Theme.gradient(atIndex: index))
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().strokeBorder(.primary, lineWidth: colorIndex == index ? 3 : 0))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) { colorIndex = index }
                                        Haptics.tap()
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Emoji") {
                    HStack {
                        Text("None")
                        Spacer()
                        if emoji.isEmpty {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        } else {
                            Button("Clear") { emoji = "" }
                                .font(.subheadline)
                        }
                    }
                    ForEach(EmojiCatalog.groups) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: emojiColumns, spacing: 8) {
                                ForEach(group.emojis, id: \.self) { choice in
                                    Text(choice)
                                        .font(.system(size: 26))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            emoji == choice ? AnyShapeStyle(Theme.primary.opacity(0.18)) : AnyShapeStyle(.clear),
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        )
                                        .onTapGesture {
                                            emoji = choice
                                            Haptics.tap()
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Languages") {
                    Picker("Term language", selection: $sourceLang) {
                        ForEach(LanguageCatalog.all) { option in
                            Text(verbatim: "\(option.flag) \(option.name)").tag(option.code)
                        }
                    }
                    Picker("Translation language", selection: $targetLang) {
                        ForEach(LanguageCatalog.all) { option in
                            Text(verbatim: "\(option.flag) \(option.name)").tag(option.code)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit deck" : "New deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private var previewCard: some View {
        HStack(spacing: 12) {
            if !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 30))
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "Deck title" : title)
                    .font(.lcTitle2)
                    .foregroundStyle(.white)
                Text(verbatim: "\(LanguageCatalog.flag(for: sourceLang)) → \(LanguageCatalog.flag(for: targetLang))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gradient(atIndex: colorIndex), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func populate() {
        guard let deck else {
            colorIndex = Int.random(in: 0..<Theme.deckGradients.count)
            return
        }
        title = deck.title
        desc = deck.desc
        sourceLang = deck.sourceLang
        targetLang = deck.targetLang
        colorIndex = deck.colorIndex
        emoji = deck.emoji
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = desc.trimmingCharacters(in: .whitespaces)

        if let deck {
            deck.title = trimmedTitle
            deck.desc = trimmedDesc
            deck.sourceLang = sourceLang
            deck.targetLang = targetLang
            deck.colorIndex = colorIndex
            deck.emoji = emoji
        } else {
            let newDeck = Deck(
                title: trimmedTitle,
                desc: trimmedDesc,
                sourceLang: sourceLang,
                targetLang: targetLang,
                colorIndex: colorIndex,
                emoji: emoji
            )
            modelContext.insert(newDeck)
        }
        try? modelContext.save()
        dismiss()
    }
}
