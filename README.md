# CodeMate for macOS

A native SwiftUI macOS app that helps students prepare for DSA and system-design
interviews at Amazon, Google, Apple, Microsoft, Meta, Netflix, OpenAI, Twitter/X,
Uber, and LinkedIn, with an in-app AI assistant, company-targeted onboarding,
neumorphic ("soft UI") design, and local progress tracking.

## What's in this MVP

- **Onboarding** — on first launch, pick which companies you're interviewing
  with (multi-select, skippable). The Practice and LLD/HLD tabs open
  pre-filtered to those companies, with questions that overlap more of your
  targets surfaced first under a "Frequently asked at {Company}" header.
  Changeable anytime from Settings → Target Companies.
- **DSA Practice** — 74 curated problems (original phrasing) across all three
  difficulty tiers, filterable by company, topic, and difficulty. Each has a
  problem statement, examples, constraints, a progressive hint ladder, and a
  "choose an approach" panel comparing brute-force → optimal solutions with
  time/space complexity.
- **Code editor** — line-numbered, monospaced, per-language starter code
  (Swift/Python/JS/Java/C++). Swift, Python, and JavaScript run locally via
  the system toolchain for quick sanity checks.
- **AI Assistant** — a chat panel grounded on the current problem + the
  student's own code. Calls the Anthropic API using a key the student enters
  in Settings (stored in Keychain, BYO-key — nothing is embedded in the
  shipped app). Falls back to a deterministic offline assistant (hints,
  approach comparison, complexity) when no key is set, so it's never a dead
  end.
- **LLD / HLD** — 12 system-design questions (parking lot, elevator, rate
  limiter, URL shortener, news feed, chat system, web crawler, tic-tac-toe
  engine, an LLM inference serving queue, a trending-topics system, a video
  streaming/recommendation service, and a ride-hailing dispatch system) with
  clarifying questions and a requirements → entities → data model → scaling
  scaffold, coached by the same assistant.
- **Progress tracking** — local SwiftData store: per-problem solve status,
  saved code/notes, hints used; a Progress tab breaks it down by company and
  topic.
- **Neumorphic design system** (`Design/NeumorphicStyle.swift`) — soft
  raised/inset surfaces, light + dark mode, company brand accents.

## Running it

Requires Xcode 15+ / macOS 14+.

```bash
swift run CodeMate       # run from the command line
```

Or open `Package.swift` directly in Xcode (File > Open) and hit Run — Xcode
treats a SwiftUI executable package like a normal app target, including the
"Signing & Capabilities" tab you'll need for distribution.

## What's still needed before selling this

This is a working MVP, not a store-ready product yet:

1. **App icon, launch assets, proper code signing & notarization** for
   distribution outside the Mac App Store, or an App Store Connect listing
   (screenshots, privacy nutrition label, review) if going through the Store.
2. **Monetization** — no paywall/StoreKit wired up yet. Decide: one-time
   purchase, subscription (StoreKit 2), or the BYO-API-key model stays free
   and you charge for the app itself.
3. **Content scale** — 74 problems / 12 design questions is a strong seed set;
   a sellable "prep" product typically wants 150–300+ problems. The data
   model (`Data/ProblemBank.swift`, `Data/SystemDesignBank.swift`) is a plain
   Swift array, so this scales by adding entries, or by moving to a bundled
   JSON/remote content pack later without touching the UI.
4. **Sandboxed code execution** — the current local runner shells out to
   `swift`/`python3`/`node` directly (fine for a student running their own
   code on their own Mac). If you ever run untrusted code server-side, that
   needs a real sandbox, not this.
5. **Real syntax highlighting** — the editor is a clean, functional
   NSTextView with line numbers; token-based highlighting isn't wired in yet.
6. **Tests** — no unit/UI test target yet.

## Project layout

```
Sources/CodeMate/
  CodeMateApp.swift          App entry point, SwiftData container, AppPreferences injection
  Design/                    Neumorphic style system
  Models/                    Problem, Company, Topic, SystemDesign, progress, assistant message, AppPreferences
  Data/                      Curated problem bank + system-design bank
  Services/                  Anthropic/offline assistant, Keychain, local code runner
  Views/
    Onboarding/               First-launch company picker + reusable CompanyPickerGrid
    Root/                    Navigation shell, Progress tab
    ProblemList/              Practice tab: filters + problem list
    Sidebar/                  Filter chip components
    Workspace/                Problem detail: statement, approaches, hints
    Editor/                   Code editor (NSViewRepresentable)
    Assistant/                AI chat panel
    SystemDesign/              LLD/HLD tab
    Settings/                  API key entry, target-company picker
```
