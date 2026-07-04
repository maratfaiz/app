import SwiftUI
import SwiftData

@main
struct LinguaCardsApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Deck.self, Card.self, StudySession.self
            )
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        SeedData.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
