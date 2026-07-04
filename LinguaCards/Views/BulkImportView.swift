import SwiftUI
import SwiftData

/// Paste "term - translation" lines to create many cards at once.
struct BulkImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var text = ""

    private var parsed: [ImportParser.ParsedCard] {
        ImportParser.parse(text)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("One card per line, for example:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(verbatim: "apple - яблоко\ndog - собака")
                    .font(.callout.monospaced())
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                TextEditor(text: $text)
                    .font(.body.monospaced())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxHeight: .infinity)

                if !text.isEmpty {
                    Text("Recognized cards: \(parsed.count)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(parsed.isEmpty ? .red : .secondary)
                }
            }
            .padding()
            .navigationTitle("Bulk import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") { importCards() }
                        .disabled(parsed.isEmpty)
                }
            }
        }
    }

    private func importCards() {
        for item in parsed {
            let card = Card(front: item.front, back: item.back)
            card.deck = deck
            modelContext.insert(card)
        }
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}
