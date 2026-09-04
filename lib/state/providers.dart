import 'dart:math';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/active_run_store.dart';
import '../data/progress_store.dart';
import '../data/remote_config_service.dart';
import '../data/review_service.dart';
import '../data/test_results_store.dart';
import '../engine/mcq_generator.dart';
import '../engine/streak.dart';
import '../engine/test_generator.dart';
import '../models/entitlements.dart';
import '../models/practice_test.dart';
import '../models/progress.dart';
import '../models/question.dart';
import '../models/question_bank.dart';
import '../models/remote_config.dart';
import '../models/scope.dart';

/// Providers whose values are loaded before the first frame and injected as
/// `ProviderScope` overrides in `main()`.
///
/// Because everything the UI needs is already resolved, no screen has to
/// render a loading spinner or an error state — which matters a great deal for
/// users who would read a spinner as "the app is broken".
Never _mustOverride(String name) =>
    throw StateError('$name must be overridden in ProviderScope');

final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) => _mustOverride('sharedPreferencesProvider'));

final Provider<QuestionBank> questionBankProvider =
    Provider<QuestionBank>((Ref ref) => _mustOverride('questionBankProvider'));

final Provider<RemoteConfigState> initialRemoteConfigProvider =
    Provider<RemoteConfigState>((Ref ref) => _mustOverride('initialRemoteConfigProvider'));

/// Source of randomness for the MCQ engine. Overridden with a seeded [Random]
/// in tests so shuffles are reproducible.
final Provider<Random> randomProvider = Provider<Random>((Ref ref) => Random());

/// The current time, injectable so streak logic is testable without a clock.
final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// What the user may access. Free-forever in this MVP; the single seam a
/// Phase-2 paywall would change. Nothing else in the app gates content.
final Provider<Entitlements> entitlementsProvider =
    Provider<Entitlements>((Ref ref) => const Entitlements.free());

final Provider<ProgressStore> progressStoreProvider = Provider<ProgressStore>(
  (Ref ref) => ProgressStore(ref.watch(sharedPreferencesProvider)),
);

final Provider<RemoteConfigService> remoteConfigServiceProvider =
    Provider<RemoteConfigService>(
  (Ref ref) => RemoteConfigService(prefs: ref.watch(sharedPreferencesProvider)),
);

final Provider<TestResultsStore> testResultsStoreProvider = Provider<TestResultsStore>(
  (Ref ref) => TestResultsStore(ref.watch(sharedPreferencesProvider)),
);

final Provider<ActiveRunStore> activeRunStoreProvider = Provider<ActiveRunStore>(
  (Ref ref) => ActiveRunStore(ref.watch(sharedPreferencesProvider)),
);

/// The id of the practice test the user left part-way through, if any, so the
/// tests list can offer to resume it. Invalidated whenever a run starts,
/// is abandoned, or finishes.
class ResumableTestNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(activeRunStoreProvider).savedTestId();

  void refresh() => state = ref.read(activeRunStoreProvider).savedTestId();
}

final NotifierProvider<ResumableTestNotifier, String?> resumableTestProvider =
    NotifierProvider<ResumableTestNotifier, String?>(ResumableTestNotifier.new);

/// The native store-review prompt. Overridden with a no-op in widget tests so
/// they never reach the platform channel.
final Provider<ReviewService> reviewServiceProvider =
    Provider<ReviewService>((Ref ref) => const ReviewService());

// ---------------------------------------------------------------------------
// Theme mode (system / light / dark)
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (ref.watch(progressStoreProvider).loadThemeMode()) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(progressStoreProvider).saveThemeMode(mode.name);
  }
}

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---------------------------------------------------------------------------
// Remote config
// ---------------------------------------------------------------------------

/// Holds the config in use and can refresh it from the network on demand.
class RemoteConfigNotifier extends Notifier<RemoteConfigState> {
  @override
  RemoteConfigState build() => ref.watch(initialRemoteConfigProvider);

  /// Fetches a fresh config. Safe to call at startup: it never blocks the UI
  /// and never surfaces an error, it just leaves the current answers in place.
  Future<RefreshOutcome> refresh() async {
    final RemoteConfigService service = ref.read(remoteConfigServiceProvider);
    final RefreshOutcome outcome = await service.refresh();
    if (outcome == RefreshOutcome.updated) {
      state = await service.loadLocal();
    }
    return outcome;
  }
}

final NotifierProvider<RemoteConfigNotifier, RemoteConfigState> remoteConfigProvider =
    NotifierProvider<RemoteConfigNotifier, RemoteConfigState>(RemoteConfigNotifier.new);

// ---------------------------------------------------------------------------
// Scope (All 128 / Starred 20)
// ---------------------------------------------------------------------------

class ScopeNotifier extends Notifier<StudyScope> {
  @override
  StudyScope build() => ref.watch(progressStoreProvider).loadScope();

  Future<void> set(StudyScope scope) async {
    state = scope;
    await ref.read(progressStoreProvider).saveScope(scope);
  }
}

final NotifierProvider<ScopeNotifier, StudyScope> scopeProvider =
    NotifierProvider<ScopeNotifier, StudyScope>(ScopeNotifier.new);

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() => ref.watch(progressStoreProvider).load();

  Future<void> record({required int questionId, required bool correct}) =>
      recordAll(<({int questionId, bool correct})>[
        (questionId: questionId, correct: correct),
      ]);

  /// Records a whole batch in one write.
  ///
  /// A finished practice test lands 20 answers at once; saving each one
  /// separately meant ~40 sequential `SharedPreferences` writes on the tap that
  /// finishes a test, which is both slow and a window for a double-tap.
  Future<void> recordAll(List<({int questionId, bool correct})> answers) async {
    if (answers.isEmpty) return;
    Progress next = state;
    for (final ({int questionId, bool correct}) a in answers) {
      next = next.recordAnswer(questionId: a.questionId, correct: a.correct);
    }
    state = next;
    await ref.read(progressStoreProvider).save(state);
    // Answering anything counts as practising today, feeding the streak. This
    // runs after awaits, so guard against the provider scope having been torn
    // down in the meantime (e.g. the user left the screen).
    try {
      await ref.read(practiceDaysProvider.notifier).recordToday();
    } on Object {
      // The provider scope was disposed before this fire-and-forget call
      // completed (e.g. the user left the screen mid-answer). The streak stamp
      // is best-effort, so dropping it here is harmless.
    }
  }

  Future<void> reset() async {
    state = Progress.empty();
    await ref.read(progressStoreProvider).reset();
    ref.invalidate(practiceDaysProvider);
    ref.invalidate(testResultsProvider);
  }
}

final NotifierProvider<ProgressNotifier, Progress> progressProvider =
    NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

// ---------------------------------------------------------------------------
// Practice days & streak
// ---------------------------------------------------------------------------

class PracticeDaysNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(progressStoreProvider).loadPracticeDays();

  /// Stamps today. Idempotent within a day, so it is safe to call per answer.
  Future<void> recordToday() async {
    final String today = dayKey(ref.read(clockProvider)());
    if (state.contains(today)) return;
    final Set<String> next = Set<String>.of(state)..add(today);
    state = next;
    await ref.read(progressStoreProvider).savePracticeDays(next);
  }
}

final NotifierProvider<PracticeDaysNotifier, Set<String>> practiceDaysProvider =
    NotifierProvider<PracticeDaysNotifier, Set<String>>(PracticeDaysNotifier.new);

/// The encouraging consecutive-day streak.
final Provider<int> streakProvider = Provider<int>((Ref ref) =>
    currentStreak(ref.watch(practiceDaysProvider), ref.watch(clockProvider)()));

// ---------------------------------------------------------------------------
// Derived pools
// ---------------------------------------------------------------------------

/// Every question that can currently be shown as a multiple-choice item.
///
/// Excludes all `variesByState` questions and any `volatile` question whose
/// answer the current remote config cannot supply.
final Provider<List<Question>> quizzablePoolProvider = Provider<List<Question>>((Ref ref) {
  final QuestionBank bank = ref.watch(questionBankProvider);
  final RemoteConfig config = ref.watch(remoteConfigProvider).config;
  return quizzableFrom(bank.questions, config);
});

/// The quizzable pool narrowed to the selected scope. Quiz and Test draw from
/// this; Study deliberately ignores it and browses all 128.
final Provider<List<Question>> scopedPoolProvider = Provider<List<Question>>((Ref ref) {
  final List<Question> pool = ref.watch(quizzablePoolProvider);
  final StudyScope scope = ref.watch(scopeProvider);
  return switch (scope) {
    StudyScope.all => pool,
    StudyScope.starred =>
      pool.where((Question q) => q.starred).toList(growable: false),
  };
});

/// Questions that exist in the bank but cannot be quizzed yet, for the
/// Settings screen to explain honestly why the pool is smaller than 128.
final Provider<int> studyOnlyCountProvider = Provider<int>((Ref ref) {
  final QuestionBank bank = ref.watch(questionBankProvider);
  return bank.questions.length - ref.watch(quizzablePoolProvider).length;
});

// ---------------------------------------------------------------------------
// Practice tests (fixed, deterministic catalogue)
// ---------------------------------------------------------------------------

/// The 20 numbered practice tests plus the Starred track.
///
/// Generated deterministically from the bank and a constant seed, so the
/// catalogue is identical on every launch and every device — no persistence of
/// the id-map is needed for stability (see README).
final Provider<List<PracticeTest>> practiceTestsProvider = Provider<List<PracticeTest>>(
  (Ref ref) => TestGenerator.generate(ref.watch(questionBankProvider)),
);

/// The 20 numbered tests only (excludes the Starred track).
final Provider<List<PracticeTest>> numberedTestsProvider = Provider<List<PracticeTest>>(
  (Ref ref) => ref
      .watch(practiceTestsProvider)
      .where((PracticeTest t) => !t.isStarredTrack)
      .toList(growable: false),
);

/// The Starred (65/20) track.
final Provider<PracticeTest> starredTestProvider = Provider<PracticeTest>(
  (Ref ref) => ref.watch(practiceTestsProvider).firstWhere((PracticeTest t) => t.isStarredTrack),
);

PracticeTest? _testById(Ref ref, String id) {
  for (final PracticeTest t in ref.watch(practiceTestsProvider)) {
    if (t.id == id) return t;
  }
  return null;
}

final testByIdProvider = Provider.family<PracticeTest?, String>(_testById);

// ---------------------------------------------------------------------------
// Test results (best score / passed per test)
// ---------------------------------------------------------------------------

class TestResultsNotifier extends Notifier<Map<String, TestStatus>> {
  @override
  Map<String, TestStatus> build() => ref.watch(testResultsStoreProvider).load();

  /// Records one finished attempt, keeping the best score. Returns true if this
  /// attempt is the *first* pass of this test — the caller uses that to decide
  /// whether to trigger the one-time store-review prompt.
  Future<bool> recordAttempt({
    required String testId,
    required int correct,
    required int total,
    required bool passed,
  }) async {
    final TestStatus previous = state[testId] ?? const TestStatus.notStarted();
    final bool firstPass = passed && !previous.passed;
    final Map<String, TestStatus> next = Map<String, TestStatus>.of(state);
    next[testId] = previous.merge(correct: correct, total: total, passed: passed);
    state = next;
    await ref.read(testResultsStoreProvider).save(next);
    return firstPass;
  }

  TestStatus statusOf(String testId) => state[testId] ?? const TestStatus.notStarted();

  /// Whether the one-time store-review prompt has already been shown.
  bool get reviewAlreadyPrompted => ref.read(testResultsStoreProvider).reviewPrompted;

  Future<void> markReviewPrompted() =>
      ref.read(testResultsStoreProvider).markReviewPrompted();
}

final NotifierProvider<TestResultsNotifier, Map<String, TestStatus>> testResultsProvider =
    NotifierProvider<TestResultsNotifier, Map<String, TestStatus>>(TestResultsNotifier.new);

final testStatusProvider = Provider.family<TestStatus, String>((Ref ref, String id) =>
    ref.watch(testResultsProvider)[id] ?? const TestStatus.notStarted());

/// How many numbered tests have been passed, for the Home/Stats summary.
final Provider<int> testsPassedProvider = Provider<int>((Ref ref) {
  final Map<String, TestStatus> results = ref.watch(testResultsProvider);
  return ref
      .watch(numberedTestsProvider)
      .where((PracticeTest t) => results[t.id]?.passed ?? false)
      .length;
});

// ---------------------------------------------------------------------------
// Misses & statistics
// ---------------------------------------------------------------------------

/// Questions to review in "Fix your misses": missed and still quizzable.
final Provider<List<Question>> missedQuestionsProvider = Provider<List<Question>>((Ref ref) {
  final Set<int> missed = ref.watch(progressProvider).missedIds;
  final List<Question> quizzable = ref.watch(quizzablePoolProvider);
  return quizzable.where((Question q) => missed.contains(q.id)).toList(growable: false);
});

/// The category with the most ground left to cover, or null when there is
/// nothing useful to target — everything is known, or no category has
/// quizzable questions left to practise.
///
/// Statistics already shows per-category mastery; this is what makes that
/// dashboard actionable rather than merely informative.
final Provider<String?> weakestCategoryProvider = Provider<String?>((Ref ref) {
  final MasterySnapshot mastery = ref.watch(masteryProvider);
  final List<Question> quizzable = ref.watch(quizzablePoolProvider);

  String? weakest;
  double worst = double.infinity;
  for (final MapEntry<String, (int, int)> e in mastery.perCategory.entries) {
    final (int known, int total) = e.value;
    if (total == 0 || known >= total) continue;
    // Only offer a topic we can actually build a quiz from.
    if (!quizzable.any((Question q) => q.category == e.key)) continue;
    final double fraction = known / total;
    if (fraction < worst) {
      worst = fraction;
      weakest = e.key;
    }
  }
  return weakest;
});

/// The quizzable questions in one category, for a topic-targeted practice run.
final categoryPoolProvider = Provider.family<List<Question>, String>(
  (Ref ref, String category) => ref
      .watch(quizzablePoolProvider)
      .where((Question q) => q.category == category)
      .toList(growable: false),
);

/// Per-category mastery (fraction answered correctly at least once), plus the
/// headline readiness figure, for the Statistics dashboard and Home meter.
class MasterySnapshot {
  const MasterySnapshot({
    required this.readiness,
    required this.knownCount,
    required this.totalCount,
    required this.perCategory,
  });

  /// 0..1 across the whole bank.
  final double readiness;
  final int knownCount;
  final int totalCount;

  /// category -> (known, total).
  final Map<String, (int known, int total)> perCategory;
}

final Provider<MasterySnapshot> masteryProvider = Provider<MasterySnapshot>((Ref ref) {
  final QuestionBank bank = ref.watch(questionBankProvider);
  final Set<int> known = ref.watch(progressProvider).everCorrectIds;

  final Map<String, (int, int)> perCategory = <String, (int, int)>{};
  for (final String category in bank.categories) {
    final List<Question> qs =
        bank.questions.where((Question q) => q.category == category).toList();
    final int knownInCat = qs.where((Question q) => known.contains(q.id)).length;
    perCategory[category] = (knownInCat, qs.length);
  }

  final int total = bank.questions.length;
  final int knownCount = known.length;
  return MasterySnapshot(
    readiness: total == 0 ? 0 : knownCount / total,
    knownCount: knownCount,
    totalCount: total,
    perCategory: perCategory,
  );
});
