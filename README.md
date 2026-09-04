# CodeMate for macOS

A native SwiftUI macOS app that helps students prepare for DSA and system-design
interviews at Amazon, Google, Apple, Microsoft, Meta, Netflix, OpenAI, Twitter/X,
Uber, and LinkedIn — an always-on-device AI assistant (no API key, no per-message
cost), an IDE-styled practice workspace, Sign in with Apple/Google, a Progress
dashboard with streaks and a contribution heatmap, Free/Pro/Max tiers sold
directly (notarized, not through the Mac App Store, billed via Polar), and a
SharePlay-based "practice together" video call with an LLD/HLD whiteboard.

## What's in this MVP

- **Sign in with Apple / Google → onboarding → app.** `AuthGateView` is the
  first screen on a fresh launch: an animated welcome, then Apple or Google
  sign-in (native `SignInWithAppleButton`; Google via OAuth 2.0 + PKCE over
  `ASWebAuthenticationSession`, no SDK). Only after signing in does the
  existing company-picker onboarding run, then the app. This is what ties a
  license/subscription to a person rather than just a device.
- **Onboarding** — pick which companies you're interviewing with (multi-select,
  skippable). Practice and LLD/HLD open pre-filtered to those companies, with
  questions overlapping more of your targets surfaced first under a
  "Frequently asked at {Company}" header. Changeable anytime from Settings.
- **DSA Practice** — 74 curated problems (original phrasing) across all three
  difficulty tiers, filterable by company, topic, and difficulty. Each has a
  problem statement, examples, constraints, a progressive hint ladder, and a
  "choose an approach" panel comparing brute-force → optimal solutions.
- **IDE-styled workspace** — the problem list is a dark file-explorer (not
  cards), the workspace has a tab bar ("two_sum.swift", closable) and a
  status bar, and the code editor is a real resizable/growable NSTextView
  with line numbers. This chrome (`Design/IDETheme.swift`) is deliberately
  separate from the softer neumorphic look used by onboarding/Settings/
  Progress — the same way a real IDE's editor differs from its surrounding
  app chrome.
- **On-device AI Assistant** — runs via Apple's on-device Foundation Models
  framework (`Services/OnDeviceAssistantService.swift`) by default: free,
  private, no API key, nothing leaves the Mac. Falls back to a BYO Anthropic
  cloud key (Settings, Keychain-stored) on unsupported hardware/OS, then to
  a deterministic offline assistant using each problem's own hints/approach
  notes — never a dead end.
- **LLD / HLD** — 12 system-design questions, including four written for the
  newer companies, plus a **Whiteboard tab** (`Views/SystemDesign/WhiteboardView.swift`):
  freehand pen, rectangle, arrow, text labels, eraser, color palette,
  undo/clear, rendered with SwiftUI's `Canvas` and persisted per-question —
  sits alongside the assistant panel so you can sketch a design and get
  help on it at the same time.
- **Practice Together (beta)** — one-on-one SharePlay session started from a
  button in the Practice sidebar. Each participant assigns the *other* a
  (possibly different) problem to solve, with a lightweight progress ping
  between them (status/attempts, never raw code — this is a challenge, not
  shared pair-programming). FaceTime itself carries audio, video (camera
  on/off is FaceTime's own control), and screen sharing; CodeMate only syncs
  this app-specific state on top of that call. Real, compiling GroupActivities
  integration (`Models/PracticeCallActivity.swift`,
  `Services/PracticeCallCoordinator.swift`), but it needs two actual Macs on
  a FaceTime call to exercise end-to-end — not testable in this environment.
- **Progress dashboard** — solved/streak/longest-streak/total-runs stat tiles,
  a GitHub-style contribution heatmap (`DailyActivity` SwiftData model, one
  row bumped per code run), and breakdowns by difficulty/company/topic.
- **Free / Pro / Max tiers, sold directly, billed via Polar** — gated on
  target-company access (Free = 1 company, Pro/Max = all 10) via a locked-chip
  state in the company filter, plus a practice-call-per-month quota tracked
  in `AppPreferences`. Because this is **not** distributed through the Mac
  App Store, StoreKit's `Product`/`Transaction` APIs don't apply (no App
  Store receipt to validate outside that sandbox) — `Services/PolarService.swift`
  validates a redeemed license key against Polar's customer-facing license-key
  API (safe to call client-side, unlike querying subscriptions by email, which
  needs a secret org token and must go through a backend). Falls back to an
  offline HMAC-signed key format (`Models/License.swift`,
  `Tools/generate_license.swift`) if Polar isn't configured yet or the key
  isn't a Polar one. `Services/StoreManager.swift` (StoreKit 2, tested via
  `StoreKit/CodeMate.storekit`) is kept in the project, unwired, for a
  possible future *separate* Mac App Store SKU.
- **Developer bypass** — `meetjethwa3@gmail.com` (see `DeveloperAccess` in
  `Models/UserAccount.swift`) always resolves to Max tier once signed in,
  license or no license, so you can test paid features without paying
  yourself. It's a client-side allowlist (fine for this purpose, not a
  security boundary) — add teammates to the same array if needed.
- **App icon** (`Marketing/icon/`) — generated via SwiftUI's `ImageRenderer`
  (`Tools/generate_icon.swift`), not a placeholder.

## Running it

Requires Xcode 15+ / macOS 14+ (the on-device assistant additionally needs
macOS 26+ with Apple Intelligence enabled; the app degrades gracefully
without it).

```bash
swift run CodeMate                 # run from the command line
./Scripts/build_app.sh && open build/CodeMate.app   # or as a real .app bundle, with icon
```

Or open `Package.swift` directly in Xcode (File > Open) and hit Run.

**Testing past the sign-in screen right now:** Apple sign-in needs the app ID
registered for that capability in your Apple Developer account plus a real
signing identity (an ad-hoc local build gets killed by macOS's code-integrity
checks if it claims that entitlement without one — confirmed while building
this; see the comments in `Scripts/build_app.sh`). Google sign-in needs a
real OAuth client ID (`AuthManager.swift` has a placeholder). Until both are
set up, `AuthGateView` shows a **"Skip sign-in (debug builds only)"** link —
compiled out of `swift build -c release` via `#if DEBUG`, so it's local-only
and never reaches a shipped build.

## Before you actually sell this

1. **Set up Sign in with Apple.** In your Apple Developer account: register
   the `com.codemate.app` identifier, enable the "Sign In with Apple"
   capability on it, and build/sign with a matching certificate (Xcode's
   automatic signing handles this cleanly; `Scripts/notarize.sh` documents
   the manual `codesign` flow with `CodeMate.entitlements`).
2. **Set up Google sign-in.** Create an OAuth 2.0 Client ID in Google Cloud
   Console (type "iOS" or "Desktop app"), register the
   `codemate://oauth-callback` redirect URI, and put the client ID in
   `AuthManager.swift`'s `googleClientID`.
3. **Set up Polar.** Create your organization at polar.sh, set up your
   Pro/Max products with a License Keys benefit, and put your organization
   ID in `PolarService.swift`. Verify the exact validate-endpoint
   request/response shape against Polar's current docs (docs.polar.sh)
   before relying on it — this was written against their documented shape
   at build time, not tested against a live account.
4. **Replace the offline license signing secret** (the HMAC fallback, not
   Polar). `Models/License.swift` and `Tools/generate_license.swift` both
   have `sharedSecret = "REPLACE_ME_WITH_A_PRIVATE_SIGNING_SECRET"` — change
   it to a real private value in both places before shipping.
5. **Code signing & notarization** — `Scripts/notarize.sh` automates
   `codesign` + `notarytool submit` + `stapler` once you have a Developer ID
   Application certificate; the script's header comments walk through the
   one-time Apple Developer Portal setup. Required for a direct download to
   open on someone else's Mac without a Gatekeeper warning.
6. **Content scale** — 74 problems / 12 design questions is a strong seed;
   a sellable "prep" product typically wants 150–300+. Both banks are plain
   Swift arrays (`Data/`), so this scales by adding entries.
7. **Sandboxed code execution** — the local runner shells out to
   `swift`/`python3`/`node` directly, which is why `CodeMate.entitlements`
   disables the App Sandbox — fine for a student running their own code on
   their own Mac, and another reason this suits direct distribution over
   the Mac App Store (which requires sandboxing).
8. **Real syntax highlighting** — the editor has line numbers but no
   token-based highlighting yet.
9. **Tests** — no unit/UI test target yet.

## Project layout

```
Sources/CodeMate/
  CodeMateApp.swift          App entry point, SwiftData container, environment injection
  Design/                    NeumorphicStyle (app chrome) + IDETheme (coding surfaces)
  Models/                    Problem, Company, SystemDesign, AppPreferences, SubscriptionTier,
                              License, PracticeCallActivity, UserAccount, DailyActivity, Whiteboard
  Data/                      Curated problem bank + system-design bank
  Services/                  On-device/Anthropic/offline assistant, Keychain, local code runner,
                              StoreManager (dormant), LicenseManager, PolarService, AuthManager,
                              PracticeCallCoordinator
  Views/
    Auth/                     Animated Sign in with Apple/Google screen
    Onboarding/               Company picker + reusable CompanyPickerGrid
    Root/                    Navigation shell, Progress dashboard
    ProblemList/              Practice tab: filters + IDE-style problem explorer
    Sidebar/                  Filter components (company dropdown, topic, difficulty)
    Workspace/                Problem workspace: tab bar, statement, approaches, hints, status bar
    Editor/                   Code editor (NSViewRepresentable)
    Assistant/                AI chat panel
    SystemDesign/              LLD/HLD tab (matching IDE treatment) + Whiteboard
    PracticeCall/              "Practice Together" SharePlay panel
    Settings/                  Account, assistant status, target companies, subscription
    Paywall/                  Free/Pro/Max pricing + license redemption
Tools/
  generate_icon.swift         Renders Marketing/icon/* from the SwiftUI logo view
  generate_license.swift      Seller-side: mints a signed offline-fallback license key
Scripts/
  build_app.sh                Builds a local CodeMate.app (icon + Info.plist), ad-hoc signed
  notarize.sh                 Real codesign + notarytool + stapler flow for direct distribution
CodeMate.entitlements         App Sandbox off (local code execution) + Sign in with Apple
StoreKit/CodeMate.storekit    Local StoreKit config (for the dormant Mac-App-Store path)
Marketing/icon/                Generated app icon PNGs + .icns
```
