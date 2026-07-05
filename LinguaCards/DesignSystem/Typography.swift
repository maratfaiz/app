import SwiftUI

/// Semantic type scale for a consistent, modern voice across the app. Display
/// and title styles use the rounded design to match the playful, friendly
/// flashcard feel; body/labels stay in the system default for readability.
extension Font {
    /// Big celebratory numbers and hero titles.
    static let lcDisplay = Font.system(size: 40, weight: .bold, design: .rounded)
    /// Screen / large section titles.
    static let lcTitle = Font.system(.title, design: .rounded).weight(.bold)
    /// Card titles, deck names.
    static let lcTitle2 = Font.system(.title2, design: .rounded).weight(.bold)
    /// Sub-section headers.
    static let lcHeadline = Font.system(.headline, design: .rounded)
    /// Rounded numeric emphasis (scores, counts).
    static let lcNumber = Font.system(.title3, design: .rounded).weight(.bold)
    /// Small uppercase-style labels.
    static let lcCaption = Font.caption.weight(.semibold)
}

/// A consistent section header used across scrollable screens.
struct SectionHeader: View {
    let title: LocalizedStringKey
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
            }
            Text(title)
                .font(.lcTitle2)
            Spacer()
        }
    }
}

extension Text {
    /// Uppercased, tracked eyebrow label (e.g. category chips, form section titles).
    func eyebrow() -> some View {
        self
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .kerning(0.6)
            .foregroundStyle(.secondary)
    }
}
