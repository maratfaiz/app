import SwiftUI
import SwiftData

/// Create or edit a deck (title, description, language pair).
struct DeckFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// nil = creating a new deck.
    let deck: Deck?

    @State private var title = ""
    @State private var desc = ""
    @State private var sourceLang = "en-US"
    @State private var targetLang = "ru-RU"

    private var isEditing: Bool { deck != nil }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $desc, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Languages") {
                    Picker("Term language", selection: $sourceLang) {
                        ForEach(LanguageCatalog.all) { option in
                            Text(verbatim: "\(option.flag) \(option.name)")
                                .tag(option.code)
                        }
                    }
                    Picker("Translation language", selection: $targetLang) {
                        ForEach(LanguageCatalog.all) { option in
                            Text(verbatim: "\(option.flag) \(option.name)")
                                .tag(option.code)
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
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        guard let deck else { return }
        title = deck.title
        desc = deck.desc
        sourceLang = deck.sourceLang
        targetLang = deck.targetLang
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = desc.trimmingCharacters(in: .whitespaces)

        if let deck {
            deck.title = trimmedTitle
            deck.desc = trimmedDesc
            deck.sourceLang = sourceLang
            deck.targetLang = targetLang
        } else {
            let newDeck = Deck(
                title: trimmedTitle,
                desc: trimmedDesc,
                sourceLang: sourceLang,
                targetLang: targetLang
            )
            modelContext.insert(newDeck)
        }
        try? modelContext.save()
        dismiss()
    }
}
