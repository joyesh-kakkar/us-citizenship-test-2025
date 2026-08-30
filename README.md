# Civics Test 2025

A calm, fully offline study app for the **USCIS 2025 civics test** (128 questions).
Flutter, one codebase for iOS and Android, Material 3, light + dark.

Built for naturalization applicants across a very wide range of age, English fluency and
comfort with phones — many on older, low-end Android devices, and many nervous about a
high-stakes life event. Every design decision follows from that: large type, high contrast,
generous tap targets, encouraging copy, and nothing that breaks when the OS text size is turned
all the way up.

### Study modes

- **Study** — Category → Subcategory → question list → detail, with every official answer
  verbatim, the "why", and a Favorite toggle.
- **Quiz** — endless multiple-choice practice from the selected scope; answer, see right/wrong
  immediately with the explanation, favorite it, then Next.
- **Practice tests** — 20 fixed, numbered tests (20 questions, 12 to pass) plus a Starred track
  (10 questions, 6 to pass). Each test is the same set on every device and every launch.
- **Test runner** — a graded run with no feedback until the end, then an encouraging pass/fail
  and a review of every missed question. A first pass triggers the native store-review prompt.
- **Flashcards** — browse questions as flip cards, filterable by category and All-128 / Starred.
- **Fix your misses** — quizzes only questions you have missed; a question leaves the list once
  you answer it correctly.
- **Favorites** — bookmark any question and review or quiz the set.
- **Statistics** — % of the bank known, per-category mastery, tests passed, and a practice streak.

This MVP is **free** — no paywall, no accounts, no purchases; everything is unlocked. See
*Monetization seam* below for how a paywall slots in later.

---

## Running it

Requires the Flutter SDK (built and verified against **3.47.1 / Dart 3.13.1**).

```bash
flutter pub get
```

```bash
flutter run
```

Check it the way CI would:

```bash
flutter analyze && flutter test
```

### What has and has not been verified

`flutter analyze` is clean and all **174 tests pass**, including layout checks of every screen at
1.5× and 2× OS text scale in **both light and dark**. The UI was also rendered and inspected in a
browser.

**An actual Android or iOS device build has not been run** on the build machine, which has neither
the Android SDK nor Xcode installed. The project is standard `flutter create` scaffolding, so it
should build normally; you will need Android Studio (or the Android command-line tools) and/or
Xcode to put it on a device. To add the Android toolchain:

```bash
brew install --cask android-commandlinetools
```

then install `platform-tools`, a `platforms;android-XX` and matching `build-tools` with
`sdkmanager`. Xcode needs roughly 25–30 GB free plus `brew install cocoapods`.

---

## Dependencies

Exactly the six the brief allows, and nothing else:

`flutter_riverpod` · `shared_preferences` · `http` · `share_plus` · `in_app_review` — plus
`flutter` itself. JSON is `dart:convert`. Test fakes use `MockClient` from
`package:http/testing.dart` (bundled inside `http`), and a `NoopReviewService` so widget tests
never reach the native review channel.

---

## The question bank

`assets/data/civics_questions.json` holds a `meta` block and 128 questions. It is loaded and
validated once at startup; a malformed bank throws rather than reaching the UI.

|  |  |
|---|---|
| Questions | 128, ids 1–128 |
| Starred (the "65/20" set) | 20 |
| `static` answers | 120 |
| `volatile` answers | 4 — ids 30, 38, 39, 57 |
| `variesByState` answers | 4 — ids 23, 29, 61, 62 |

Passing thresholds come from `meta.passing` and are never hardcoded elsewhere: the standard test
asks 20 and needs 12; the 65/20 test asks 10 and needs 6.

**Official answers are rendered verbatim, always.** Where USCIS accepts several answers, Study and
the review screens list all of them. The *wrong* options in quizzes were authored for this app and
are not official USCIS content — Settings says so plainly.

---

## Setting up the answers that change

Four answers (President, Vice President, Speaker, Chief Justice) change with elections and
appointments, so they live outside the app binary.

**`kRemoteConfigUrl` is in [`lib/config.dart`](lib/config.dart)**, left as a clearly marked
`REPLACE_ME` placeholder. While it is a placeholder the app never touches the network at all;
"Check for updates" in Settings reports that no update address is configured.

To push answer updates without shipping a new build:

1. Host a copy of `assets/data/remote_config.json` at an HTTPS URL.
2. Set `kRemoteConfigUrl` to that URL.
3. Edit the hosted file whenever an office changes.

To change the answers baked into the build instead, edit `assets/data/remote_config.json`
directly. An entry needs at least one `correct` answer and three `distractors` to be quizzable;
empty arrays are valid and simply leave that question study-only. The bundled file ships
populated, so all four volatile questions are quizzable offline on first launch.

**Resolution order is cached → bundled, never blocking.** At startup the app reads only local
data, so the first screen is the real one — no spinner, no error state. A network refresh runs
after the first frame; offline, timeout, non-200, malformed JSON and wrong-shape responses all
silently keep whatever answers are already in use. One malformed entry is dropped without
invalidating the rest of the document.

---

## Switching the visual direction

The design is "Confident & Warm". A re-skin touches only three things, all in
[`lib/theme/app_theme.dart`](lib/theme/app_theme.dart) — the component kit and every layout stay
put:

- **Color tokens** in `AppColors` (e.g. `ink` `#1C2B4A`, `accent` `#D33F49`, `success` `#3E9B6B`,
  and the dark surfaces). Keep pairs at WCAG AA.
- **The two font families** — `AppTheme.displayFont` (Nunito, headings) and `AppTheme.bodyFont`
  (Nunito Sans, body). Font files live in `assets/fonts/` and are wired in `pubspec.yaml`.
- **The two radii** in `AppRadii` — `card` (20) and `control` (13).

Everything else — `PrimaryButton`, `AppCard`, `StatMeter`, `OptionTile`, `TestCard`, `ToolTile`,
`SectionHeader`, `FavoriteButton`, `ScopeToggle` in [`lib/widgets/`](lib/widgets) — reads from
those tokens, so a new palette or typeface propagates everywhere.

---

## How it is put together

```
lib/
  config.dart      kRemoteConfigUrl, test seed/count, timeouts, prefs keys, asset paths
  models/          Question · QuestionBank · QuizMeta · RemoteConfig · McqItem · Progress
                   Scope · PracticeTest · Entitlements
  data/            question_repository · remote_config_service · progress_store
                   favorites_store · test_results_store · review_service
  engine/          mcq_generator · test_generator · streak   (all pure, no Flutter imports)
  state/           Riverpod providers (incl. entitlements) + quiz/test controllers
  screens/         home · study (categories/questions/detail) · quiz · practice_tests
                   test · test_result · flashcards · favorites · fix_misses · statistics · settings
  widgets/         the component kit listed above + answer_widgets
  theme/           app_theme (tokens + light/dark)
```

### The MCQ engine

```dart
bool isQuizzable(Question q, RemoteConfig config);
McqItem? buildMcq(Question q, RemoteConfig config, {required Random rng});
```

Guarantees, all covered by tests: exactly 4 options, all distinct case-insensitively, the correct
option is one of the officially acceptable answers, no distractor duplicates it, and the source
lists are never mutated. `variesByState` questions always return null (study-only in this MVP);
`volatile` questions return null unless the config supplies a usable entry.

### The practice-test generator

[`lib/engine/test_generator.dart`](lib/engine/test_generator.dart) builds the catalogue
deterministically from a fixed seed (`kPracticeTestSeed`), so "Test 5" is the same 20 questions on
every device and every launch. Each test covers the three categories proportionally, spreads usage
across the bank, and never repeats a question within a test. `variesByState` questions are
excluded. Tests in [`test/test_generator_test.dart`](test/test_generator_test.dart) pin the
determinism and these structural guarantees.

### Monetization seam (Phase 2, nothing built)

`PracticeTest.premium` exists on every test (all `false` now) and a single `entitlementsProvider`
returns "everything unlocked". A future paywall changes only that provider and the one
`Entitlements.canAccess` check — no screen inspects entitlements directly today.

### Privacy

No backend, no accounts, no analytics, no ads, no trackers. Progress, favorites, settings and test
results live in `shared_preferences` on the device. The only network call in the whole app is the
optional remote-config refresh; `share_plus` and `in_app_review` invoke OS surfaces, not a server.

---

## Working session notes — kept, added, changed

This build **extended an existing working app** rather than scaffolding fresh.

**Kept intact:** the Study browse flow and its data wiring, the question repository and models, the
remote-config service and its fallback chain, the MCQ engine, the light/dark theme, and both data
files. The theme was aligned to the Confident & Warm tokens, not replaced.

**Added:** the practice-test catalogue + runner, the Starred track, Flashcards, Favorites,
Fix-your-misses, Statistics with a streak, the readiness meter, the reusable component kit, the
`entitlements` seam, and Settings actions for Rate us (`in_app_review`) and Share app
(`share_plus`). Study gained the subcategory level and a per-question Favorite toggle.

**Deliberately changed / fixed this session:**

- **Practice-test runner scoping bug (was a production crash).** `testControllerProvider` mounted
  in the root scope, so it read the un-overridden `activeTestProvider` and threw
  `activeTestProvider must be overridden` — opening *any* practice test would have crashed. Fixed
  by declaring the controller with `dependencies: [activeTestProvider]`, which re-scopes it into
  the runner's nested `ProviderScope`.
- **Text-scale overflows.** The Home practice-test strip had a fixed `height: 156`, the Home
  quick-tile grid used a fixed `childAspectRatio`, and the Flashcards card/nav rows weren't
  flexible — all clipped at large OS text sizes (some even at 1×). Replaced with content-sized
  `IntrinsicHeight` layouts and flexible text so they grow with the text size. The failing
  large-scale layout tests now pass.
- **Volatile questions in the catalogue.** The generator includes volatile ids so the catalogue is
  stable regardless of later network state; the runner drops any that the current config can't
  answer and scales the pass threshold to match. (Documented in the generator's doc comment.)
- Tightened one study test that over-matched the USCIS URL (it appears in both the note and the
  question's own explanation), and added the dedicated generator test suite the brief calls for.

---

## Accessibility

Non-negotiable for this audience, and enforced by tests where it can be:

- Large type by default; every tap target ≥ 48 dp, primary actions ≥ 56 dp (minimums, so controls
  grow rather than clip).
- **`MediaQuery.textScaler` is never clamped.** Widget tests re-render all screens at 1.5× and 2×,
  light and dark, asserting zero overflow.
- All text/background pairs meet **WCAG AA**; light and dark both.
- Correct/incorrect is never signalled by colour alone. A wrong answer shows the correct one
  immediately and is never framed as failure. Empty states invite action rather than dead-end.
- Screen-reader labels on options, meters and tiles; result banners are live regions.

---

## Where Phase 2 plugs in

Nothing below is built — these are the seams left for it.

- **Paywall / purchases** — the `entitlementsProvider` and `PracticeTest.premium` flag described
  above.
- **Per-state answers** — the single `AnswerType.variesByState` branch in
  [`mcq_generator.dart`](lib/engine/mcq_generator.dart), plus a 50-state dataset and a state
  setting. `stateField` and `distractorStrategy` are already parsed onto `Question`.
- **Audio / text-to-speech** — attaches to `OfficialAnswersList` and the question text; no engine
  or storage change.
- **Spaced repetition** — extends the progress store; the engine stays untouched.
- **Localization** — all user-facing strings live in the widget layer, none in models, data or
  engine.
