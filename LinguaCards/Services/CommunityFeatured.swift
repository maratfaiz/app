import Foundation

extension CommunityStore {
    /// Curated decks that populate the Explore tab out of the box, so the
    /// community never feels empty.
    static let featured: [CommunityDeck] = [
        CommunityDeck(
            title: "Spanish for Travel",
            desc: "Survival phrases for your next trip to Spain or Latin America.",
            sourceLang: "en-US", targetLang: "es-ES", subject: "Travel",
            authorName: "Sofía Márquez", authorHandle: "@sofiam", authorColorIndex: 1, saves: 4820,
            cards: [
                .init(front: "hello", back: "hola", example: "¡Hola! ¿Cómo estás?"),
                .init(front: "thank you", back: "gracias", example: "Muchas gracias por tu ayuda."),
                .init(front: "please", back: "por favor", example: "Un café, por favor."),
                .init(front: "where is the bathroom?", back: "¿dónde está el baño?", example: nil),
                .init(front: "how much is it?", back: "¿cuánto cuesta?", example: nil),
                .init(front: "the bill, please", back: "la cuenta, por favor", example: nil),
                .init(front: "good morning", back: "buenos días", example: "Buenos días, señora."),
                .init(front: "excuse me", back: "perdón", example: nil),
            ]
        ),
        CommunityDeck(
            title: "French Kitchen Essentials",
            desc: "Cook and shop in French — the words you actually need.",
            sourceLang: "en-US", targetLang: "fr-FR", subject: "Food",
            authorName: "Luc Moreau", authorHandle: "@lucm", authorColorIndex: 4, saves: 3110,
            cards: [
                .init(front: "bread", back: "le pain", example: "J'achète du pain frais."),
                .init(front: "cheese", back: "le fromage", example: nil),
                .init(front: "wine", back: "le vin", example: "Un verre de vin rouge."),
                .init(front: "water", back: "l'eau", example: nil),
                .init(front: "apple", back: "la pomme", example: nil),
                .init(front: "to eat", back: "manger", example: "On va manger à huit heures."),
                .init(front: "delicious", back: "délicieux", example: nil),
            ]
        ),
        CommunityDeck(
            title: "German A1 Basics",
            desc: "Your first 8 German words and greetings.",
            sourceLang: "en-US", targetLang: "de-DE", subject: "Beginner",
            authorName: "Anna Weber", authorHandle: "@annaw", authorColorIndex: 6, saves: 5640,
            cards: [
                .init(front: "hello", back: "hallo", example: nil),
                .init(front: "goodbye", back: "tschüss", example: nil),
                .init(front: "yes", back: "ja", example: nil),
                .init(front: "no", back: "nein", example: nil),
                .init(front: "thank you", back: "danke", example: "Danke schön!"),
                .init(front: "please", back: "bitte", example: nil),
                .init(front: "my name is", back: "ich heiße", example: "Ich heiße Anna."),
                .init(front: "I don't understand", back: "ich verstehe nicht", example: nil),
            ]
        ),
        CommunityDeck(
            title: "Business English",
            desc: "Sound sharp in meetings and emails.",
            sourceLang: "en-US", targetLang: "ru-RU", subject: "Business",
            authorName: "Mark Chen", authorHandle: "@markc", authorColorIndex: 0, saves: 2270,
            cards: [
                .init(front: "deadline", back: "срок сдачи", example: "The deadline is Friday."),
                .init(front: "meeting", back: "встреча", example: nil),
                .init(front: "invoice", back: "счёт", example: nil),
                .init(front: "agenda", back: "повестка дня", example: nil),
                .init(front: "to schedule", back: "запланировать", example: nil),
                .init(front: "feedback", back: "обратная связь", example: nil),
            ]
        ),
        CommunityDeck(
            title: "Italian Greetings",
            desc: "Warm up your Italian with everyday hellos.",
            sourceLang: "en-US", targetLang: "it-IT", subject: "Beginner",
            authorName: "Giulia Rossi", authorHandle: "@giur", authorColorIndex: 5, saves: 1890,
            cards: [
                .init(front: "hello / hi", back: "ciao", example: "Ciao, come stai?"),
                .init(front: "good evening", back: "buonasera", example: nil),
                .init(front: "please", back: "per favore", example: nil),
                .init(front: "thank you", back: "grazie", example: nil),
                .init(front: "you're welcome", back: "prego", example: nil),
                .init(front: "see you soon", back: "a presto", example: nil),
            ]
        ),
        CommunityDeck(
            title: "Japanese Survival Kit",
            desc: "Essential phrases for your first days in Japan.",
            sourceLang: "en-US", targetLang: "ja-JP", subject: "Travel",
            authorName: "Kenji Ito", authorHandle: "@kenji", authorColorIndex: 7, saves: 6720,
            cards: [
                .init(front: "hello", back: "こんにちは", example: nil),
                .init(front: "thank you", back: "ありがとう", example: nil),
                .init(front: "excuse me / sorry", back: "すみません", example: nil),
                .init(front: "yes", back: "はい", example: nil),
                .init(front: "no", back: "いいえ", example: nil),
                .init(front: "how much?", back: "いくらですか", example: nil),
                .init(front: "delicious", back: "おいしい", example: nil),
            ]
        ),
    ]
}
