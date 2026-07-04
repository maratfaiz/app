# LinguaCards

A native iOS language-learning flashcard app in the spirit of Quizlet: decks of term/translation cards, four study modes, spaced repetition (simplified SM-2), progress stats and text-to-speech. Offline-first — all data lives on device in SwiftData, no backend.

## Requirements & building

- **Xcode 16 or newer** (the project uses file-system-synchronized groups)
- **iOS 17.0+** deployment target, Swift 5.9+

```
open LinguaCards.xcodeproj
```

Select the *LinguaCards* scheme and an iOS 17+ simulator, then **Run** (⌘R). No dependencies, no configuration — the project builds out of the box. On first launch a sample deck ("English Essentials", 20 English–Russian words) is seeded automatically.

Run the unit tests with **⌘U** (or `xcodebuild test -scheme LinguaCards -destination 'platform=iOS Simulator,name=iPhone 16'`).

## Architecture

MVVM on top of SwiftUI + SwiftData:

```
LinguaCards/
├── LinguaCardsApp.swift        # @main: ModelContainer setup + first-launch seeding
├── Models/                     # SwiftData @Model classes
│   ├── Deck.swift              # title, desc, languages, cards[], sessions[] + stats helpers
│   ├── Card.swift              # front/back/example + SM-2 state (ease, interval, reps, nextReview)
│   └── StudySession.swift      # per-session record (date, deck, correct/incorrect, mode)
├── ViewModels/                 # @Observable classes, one per study mode
│   ├── FlashcardsViewModel.swift
│   ├── QuizViewModel.swift
│   ├── TypingTestViewModel.swift
│   ├── MatchGameViewModel.swift
│   └── ReviewViewModel.swift   # SRS review across one or many decks
├── Services/                   # Pure, unit-testable logic + system wrappers
│   ├── SRSScheduler.swift      # simplified SM-2 (pure functions)
│   ├── AnswerMatcher.swift     # fuzzy answer matching (pure functions)
│   ├── ImportParser.swift      # "term - translation" bulk import parsing
│   ├── StatsService.swift      # streaks + daily activity aggregation
│   ├── SpeechService.swift     # AVSpeechSynthesizer wrapper
│   ├── Haptics.swift           # haptic feedback helpers
│   ├── LanguageCatalog.swift   # supported languages for pickers/TTS
│   └── SeedData.swift          # sample deck inserted on first launch
├── Views/
│   ├── RootView.swift          # TabView: Decks / Review / Stats
│   ├── DeckListView.swift      # deck list with progress rings and due badges
│   ├── DeckDetailView.swift    # stats header, study launcher, card list
│   ├── DeckFormView.swift      # create/rename deck, language pickers
│   ├── CardFormView.swift      # add/edit card
│   ├── BulkImportView.swift    # paste-to-import
│   ├── ReviewTodayView.swift   # due cards across all decks
│   ├── StatsView.swift         # streak, 14-day chart (Swift Charts), mastery per deck
│   ├── Study/                  # the four study mode screens + SRS review screen
│   └── Components/             # FlipCardView, EmptyStateView, SpeakerButton, StudyResultsView
├── Resources/
│   └── Localizable.xcstrings   # string catalog, English (source) + Russian
└── Assets.xcassets
LinguaCardsTests/               # XCTest unit tests (run on simulator)
```

Design notes:

- **Study-mode logic lives in `@Observable` view models**; deck/card CRUD uses SwiftUI's `@Query` + `modelContext` directly, which is the idiomatic SwiftData pattern for simple list/form screens.
- **The SRS scheduler and answer matcher are pure functions** (`SRSScheduler`, `AnswerMatcher`) operating on value types, so they are unit-tested without any SwiftData/UI machinery.
- **Localization from day one**: all UI strings go through a string catalog (`Localizable.xcstrings`) with English as the source language and full Russian translations.

## What's implemented

- **Decks** — create / rename / delete; title, description, source & target language; list with card count, due badge and mastery progress ring; empty states with CTAs.
- **Cards** — add / edit / delete; front, back, optional example sentence; bulk import by pasting `term - translation` lines (also accepts `–`, `—`, `=`, tab separators).
- **Study modes**
  - *Flashcards*: tap to flip with a 3D rotation, swipe right = known / left = unknown (with drag badges and haptics), on-screen ✓/✕ buttons as an alternative.
  - *Multiple choice*: 4 options drawn from other cards in the deck (needs ≥ 4 cards).
  - *Typing test*: fuzzy matching — case- and diacritic-insensitive, punctuation/whitespace tolerant, small typos accepted on longer words ("almost correct" is graded as *Hard*).
  - *Match game*: 6-pair grid of terms and translations, timed, mistake counter.
- **Spaced repetition** — simplified SM-2 with Again / Hard / Good / Easy grades; each card stores ease factor, interval, repetition count and next review date; "Review today" tab shows due cards across all decks (all at once or per deck); every study mode feeds back into the schedule (e.g. a wrong quiz answer is a lapse).
- **Progress & stats** — per-deck % mastered (mature cards: ≥ 3 successful reviews and interval ≥ 21 days), cards due today, study streak; global stats tab with a stacked 14-day activity bar chart (Swift Charts) and mastery-per-deck bars.
- **Text-to-speech** — speaker button on every card/list row via `AVSpeechSynthesizer`, using the deck's language codes with graceful voice fallback.
- **UX** — light & dark mode, haptic feedback on swipes and correct/wrong answers, localizable strings (English + Russian), empty states everywhere.

## Simplified SM-2

| Grade | Repetitions | Interval | Ease |
|-------|-------------|----------|------|
| Again | reset to 0 | 0 (retry in ~10 min) | −0.20 |
| Hard  | +1 | ×1.2 (min 1 day) | −0.15 |
| Good  | +1 | 1 day → 6 days → ×ease | unchanged |
| Easy  | +1 | 2 days → 8 days → ×ease×1.3 | +0.15 |

Ease is clamped to [1.3, 3.0]. A card is *due* when its next review date is today or earlier; new cards are due immediately.

## Tests

`LinguaCardsTests` covers the pure logic:

- `SRSSchedulerTests` — new-card progression (1 → 6 → ×ease days), lapse behavior, ease clamping, Hard/Easy interval math, monotonic growth.
- `AnswerMatcherTests` — case/diacritic/punctuation insensitivity, typo tolerance by word length, alternative answers ("дом / здание"), Levenshtein distance.
- `ImportParserTests` — separator variants, whitespace trimming, invalid-line skipping.

## Not implemented (ideas for later)

- iCloud sync (SwiftData + CloudKit)
- Deck sharing / import from CSV files
- Reminders & notifications for due reviews
- Images and audio recordings on cards
