import Foundation
import SwiftData

/// Inserts the sample English-Russian deck on first launch.
enum SeedData {
    static let seededKey = "com.linguacards.didSeedSampleData"

    static func seedIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: seededKey) else { return }
        defaults.set(true, forKey: seededKey)

        let existing = (try? context.fetchCount(FetchDescriptor<Deck>())) ?? 0
        guard existing == 0 else { return }

        insertSampleDeck(into: context)
    }

    static func insertSampleDeck(into context: ModelContext) {
        let deck = Deck(
            title: "English Essentials",
            desc: "20 everyday English words with Russian translations",
            sourceLang: "en-US",
            targetLang: "ru-RU"
        )
        context.insert(deck)

        for (front, back, example) in sampleWords {
            let card = Card(front: front, back: back, example: example)
            card.deck = deck
            context.insert(card)
        }

        try? context.save()
    }

    static let sampleWords: [(String, String, String?)] = [
        ("house", "дом", "We bought a new house last year."),
        ("water", "вода", "Could I have a glass of water?"),
        ("book", "книга", "She is reading an interesting book."),
        ("friend", "друг", "He is my best friend."),
        ("time", "время", "What time is it now?"),
        ("day", "день", "Have a nice day!"),
        ("work", "работа", "I have a lot of work today."),
        ("city", "город", "Moscow is a very big city."),
        ("food", "еда", "The food in this cafe is delicious."),
        ("family", "семья", "My family lives in the countryside."),
        ("morning", "утро", "I drink coffee every morning."),
        ("night", "ночь", "The stars are bright at night."),
        ("street", "улица", "Our street is quiet and green."),
        ("money", "деньги", "He saves money for a trip."),
        ("weather", "погода", "The weather is great today."),
        ("language", "язык", "Russian is a beautiful language."),
        ("question", "вопрос", "May I ask you a question?"),
        ("answer", "ответ", "I don't know the answer."),
        ("travel", "путешествовать", "We love to travel in summer."),
        ("learn", "учить", "I learn ten new words every day."),
    ]
}
