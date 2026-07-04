# LinguaCards

A native iOS language-learning flashcard app in the spirit of Quizlet: decks of term/translation cards, **six study modes** (Learn, Flashcards, Write, Match, Multiple choice, Test) plus spaced-repetition review, a polished gradient design system, progress stats and text-to-speech. Offline-first — all data lives on device in SwiftData, no backend.

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
├── DesignSystem/
│   ├── Theme.swift             # brand palette, per-deck gradients, spacing/radii, Color(hex:)
│   └── Components.swift        # PrimaryButton, ProgressRing, GradientProgressBar, confetti, …
├── Models/                     # SwiftData @Model classes
│   ├── Deck.swift              # title, desc, languages, cards[], sessions[] + stats helpers
│   ├── Card.swift              # front/back/example, isStarred, SM-2 state, MasteryLevel
│   └── StudySession.swift      # per-session record (date, deck, correct/incorrect, mode)
├── ViewModels/                 # @Observable classes, one per study mode
│   ├── LearnViewModel.swift    # adaptive Learn mode
│   ├── TestViewModel.swift     # graded mixed-question Test
│   ├── FlashcardsViewModel.swift
│   ├── QuizViewModel.swift
│   ├── TypingTestViewModel.swift
│   ├── MatchGameViewModel.swift
│   └── ReviewViewModel.swift   # SRS review across one or many decks
├── Services/                   # Pure, unit-testable logic + system wrappers
│   ├── SRSScheduler.swift      # simplified SM-2 (pure functions)
│   ├── LearnEngine.swift       # adaptive box/queue engine for Learn (pure functions)
│   ├── AnswerMatcher.swift     # fuzzy answer matching (pure functions)
│   ├── ImportParser.swift      # "term - translation" bulk import parsing
│   ├── StudyOptions.swift      # study direction + starred/shuffle options
│   ├── StatsService.swift      # streaks + daily activity aggregation
│   ├── SpeechService.swift     # AVSpeechSynthesizer wrapper
│   ├── Haptics.swift           # haptic feedback helpers
│   ├── LanguageCatalog.swift   # supported languages for pickers/TTS
│   └── SeedData.swift          # sample deck inserted on first launch
├── Views/
│   ├── RootView.swift          # TabView (Decks / Review / Stats) + onboarding gate
│   ├── OnboardingView.swift    # first-launch welcome pages
│   ├── DeckListView.swift      # gradient deck cards + search
│   ├── DeckDetailView.swift    # gradient header, study options, mode grid, card list
│   ├── DeckFormView.swift      # create/rename deck, language pickers
│   ├── CardFormView.swift      # add/edit card
│   ├── BulkImportView.swift    # paste-to-import
│   ├── ReviewTodayView.swift   # due cards across all decks
│   ├── StatsView.swift         # streak, mastery breakdown, 14-day chart, per-deck mastery
│   ├── Study/                  # Learn, Flashcards, Quiz, Write, Match, Test, Review screens
│   └── Components/             # FlipCardView, MasteryBar, EmptyStateView, SpeakerButton, …
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

- **Design system** — a brand indigo→violet gradient identity; every deck gets its own deterministic gradient; reusable `PrimaryButton`, `ProgressRing`, `GradientProgressBar`, `MasteryBar`, stat pills and a confetti burst on great results. Full light & dark support.
- **Onboarding** — a three-page gradient welcome on first launch (gated by `@AppStorage`).
- **Decks** — create / rename / delete; title, description, source & target language; home screen of vibrant gradient deck cards with card count, due badge, starred count and mastery ring; **search** across decks; empty states with CTAs.
- **Cards** — add / edit / delete; front, back, optional example sentence; **star / favorite** any card; bulk import by pasting `term - translation` lines (also accepts `–`, `—`, `=`, tab separators).
- **Study options** — per-session **direction toggle** (term→translation or translation→term) and **starred-only** filter, applied across every mode.
- **Study modes**
  - *Learn* (flagship): Quizlet-style adaptive session — each term escalates from multiple-choice recognition to written recall and must be answered correctly twice to graduate; wrong answers are requeued; a progress bar tracks mastered vs. remaining. Backed by the pure, tested `LearnEngine`.
  - *Flashcards*: tap to flip with a 3D rotation onto the deck's gradient, swipe right = known / left = unknown (drag badges + haptics), on-card star + speaker, ✓/✕ buttons.
  - *Test*: a graded exam mixing written, multiple-choice and true/false questions; answer them all, then get a score ring and a per-question review with the correct answers.
  - *Multiple choice*: 4 options drawn from other cards (needs ≥ 4 cards).
  - *Write*: fuzzy matching — case/diacritic-insensitive, punctuation/whitespace tolerant, small typos accepted on longer words via Damerau-Levenshtein ("almost correct" grades as *Hard*).
  - *Match*: 6-pair timed grid with a mistake counter.
- **Spaced repetition** — simplified SM-2 with Again / Hard / Good / Easy grades; each card stores ease factor, interval, repetition count and next review date; "Review today" tab shows due cards across all decks (all at once or per deck); **every** study mode feeds back into the schedule.
- **Progress & stats** — three-way mastery buckets (Not studied / Still learning / Mastered) shown as a segmented `MasteryBar` per deck and overall; per-deck % mastered, cards due, study streak; global stats tab with a stacked 14-day activity chart (Swift Charts).
- **Text-to-speech** — speaker button on every card/prompt via `AVSpeechSynthesizer`, using the deck's language codes with graceful voice fallback.
- **UX** — light & dark mode, haptic feedback throughout, localizable strings (English + Russian, ~138 keys), empty states everywhere.

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
- `AnswerMatcherTests` — case/diacritic/punctuation insensitivity, typo tolerance by word length, alternative answers ("дом / здание"), adjacent-transposition (Damerau-Levenshtein) distance.
- `ImportParserTests` — separator variants, whitespace trimming, invalid-line skipping.
- `LearnEngineTests` — Learn-mode queue: graduation after N correct, wrong-answer reset & requeue (no immediate repeat), termination and monotonic progress.

## Not implemented (ideas for later)

- iCloud sync (SwiftData + CloudKit)
- Deck sharing / import from CSV files
- Reminders & notifications for due reviews
- Images and audio recordings on cards
