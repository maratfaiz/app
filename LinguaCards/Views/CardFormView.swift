import SwiftUI
import SwiftData

/// Create or edit a single card in a deck.
struct CardFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    /// nil = creating a new card.
    let card: Card?

    @State private var front = ""
    @State private var back = ""
    @State private var example = ""
    /// Keeps the sheet open after saving so several cards can be added in a row.
    @State private var addAnother = false

    private var isEditing: Bool { card != nil }

    private var canSave: Bool {
        !front.trimmingCharacters(in: .whitespaces).isEmpty
            && !back.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Term") {
                    TextField("Term", text: $front, axis: .vertical)
                }
                Section("Translation") {
                    TextField("Translation", text: $back, axis: .vertical)
                }
                Section("Example sentence (optional)") {
                    TextField("Example", text: $example, axis: .vertical)
                        .lineLimit(2...4)
                }
                if !isEditing {
                    Section {
                        Toggle("Add another after saving", isOn: $addAnother)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit card" : "New card")
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
        guard let card else { return }
        front = card.front
        back = card.back
        example = card.example ?? ""
    }

    private func save() {
        let trimmedFront = front.trimmingCharacters(in: .whitespaces)
        let trimmedBack = back.trimmingCharacters(in: .whitespaces)
        let trimmedExample = example.trimmingCharacters(in: .whitespaces)

        if let card {
            card.front = trimmedFront
            card.back = trimmedBack
            card.example = trimmedExample.isEmpty ? nil : trimmedExample
        } else {
            let newCard = Card(
                front: trimmedFront,
                back: trimmedBack,
                example: trimmedExample.isEmpty ? nil : trimmedExample
            )
            newCard.deck = deck
            modelContext.insert(newCard)
        }
        try? modelContext.save()

        if !isEditing && addAnother {
            front = ""
            back = ""
            example = ""
        } else {
            dismiss()
        }
    }
}
