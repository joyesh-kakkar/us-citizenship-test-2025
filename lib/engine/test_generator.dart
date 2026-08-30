import 'dart:math';

import '../config.dart';
import '../models/practice_test.dart';
import '../models/question.dart';
import '../models/question_bank.dart';

/// Builds the fixed catalogue of practice tests deterministically from the
/// bank, so "Test 5" is the same 20 questions on every device and every launch.
///
/// Pure: the same [bank] and seed always produce identical tests. Persistence
/// lives in `TestCatalogStore`; this file has no I/O.
///
/// Rules, matching the real exam pools:
///  * `variesByState` questions are always excluded (study-only this MVP);
///  * `volatile` questions are included — the bundled config supplies them, so
///    the catalogue is stable regardless of later network state;
///  * each test covers the three categories proportionally to their share of
///    the eligible pool, and questions are spread evenly across the 20 tests
///    (a question may appear in more than one test, like the real pools);
///  * no question repeats within a single test.
abstract final class TestGenerator {
  /// The pool eligible for tests: everything except `variesByState`.
  static List<Question> eligible(QuestionBank bank) => bank.questions
      .where((Question q) => q.answerType != AnswerType.variesByState)
      .toList(growable: false);

  /// The full catalogue: [kPracticeTestCount] numbered tests plus the Starred
  /// track, in display order.
  static List<PracticeTest> generate(
    QuestionBank bank, {
    int seed = kPracticeTestSeed,
  }) =>
      <PracticeTest>[
        ...generateNumbered(bank, seed: seed),
        generateStarredTrack(bank, seed: seed),
      ];

  /// The 20 standard tests of [QuizMeta.standard] size.
  static List<PracticeTest> generateNumbered(
    QuestionBank bank, {
    int seed = kPracticeTestSeed,
  }) {
    final int perTest = bank.meta.standard.asked;
    final int needToPass = bank.meta.standard.needToPass;
    final List<Question> pool = eligible(bank);

    // Deal each category from its own seeded shuffle via a rotating cursor, so
    // usage is spread evenly across all tests and the result is deterministic.
    final List<String> categories = bank.categories;
    final Map<String, List<int>> dealt = <String, List<int>>{};
    for (final String category in categories) {
      final List<Question> inCat =
          pool.where((Question q) => q.category == category).toList()
            ..sort((Question a, Question b) => a.id.compareTo(b.id));
      final List<int> ids = inCat.map((Question q) => q.id).toList();
      _seededShuffle(ids, Random(seed ^ category.hashCode));
      dealt[category] = ids;
    }
    final Map<String, int> cursor = <String, int>{
      for (final String c in categories) c: 0,
    };

    final Map<String, int> seats = _allocateSeats(
      total: perTest,
      weights: <String, int>{
        for (final String c in categories) c: dealt[c]!.length,
      },
      order: categories,
    );

    final List<PracticeTest> tests = <PracticeTest>[];
    for (int t = 0; t < kPracticeTestCount; t++) {
      final List<int> questionIds = <int>[];
      for (final String category in categories) {
        final List<int> ids = dealt[category]!;
        for (int i = 0; i < seats[category]!; i++) {
          questionIds.add(ids[cursor[category]! % ids.length]);
          cursor[category] = cursor[category]! + 1;
        }
      }
      // Mix category order within the test so it does not read in blocks.
      _seededShuffle(questionIds, Random((seed * 31) + t + 1));
      tests.add(PracticeTest(
        id: 'test-${t + 1}',
        title: 'Test ${t + 1}',
        questionIds: List<int>.unmodifiable(questionIds),
        needToPass: needToPass,
      ));
    }
    return tests;
  }

  /// The 65/20 track: [QuizMeta.special6520] questions from the starred set.
  static PracticeTest generateStarredTrack(
    QuestionBank bank, {
    int seed = kPracticeTestSeed,
  }) {
    final int size = bank.meta.special6520.asked;
    final List<int> starred = eligible(bank)
        .where((Question q) => q.starred)
        .map((Question q) => q.id)
        .toList()
      ..sort();
    _seededShuffle(starred, Random(seed ^ 'starred'.hashCode));
    final List<int> chosen = starred.take(size).toList()..sort();
    return PracticeTest(
      id: 'starred',
      title: 'Starred 10',
      questionIds: List<int>.unmodifiable(chosen),
      needToPass: bank.meta.special6520.needToPass,
      isStarredTrack: true,
    );
  }

  /// Largest-remainder allocation of [total] seats across weighted categories,
  /// guaranteeing at least one seat to any non-empty category.
  static Map<String, int> _allocateSeats({
    required int total,
    required Map<String, int> weights,
    required List<String> order,
  }) {
    final int sum = weights.values.fold(0, (int a, int b) => a + b);
    if (sum == 0) return <String, int>{for (final String c in order) c: 0};

    final Map<String, int> seats = <String, int>{};
    final Map<String, double> remainder = <String, double>{};
    int assigned = 0;
    for (final String c in order) {
      final double exact = total * weights[c]! / sum;
      int floor = exact.floor();
      if (weights[c]! > 0 && floor == 0) floor = 1; // guarantee coverage
      seats[c] = floor;
      remainder[c] = exact - exact.floor();
      assigned += floor;
    }
    // Hand out or reclaim seats to hit exactly [total].
    final List<String> byRemainder = order.toList()
      ..sort((String a, String b) => remainder[b]!.compareTo(remainder[a]!));
    int i = 0;
    while (assigned < total) {
      final String c = byRemainder[i % byRemainder.length];
      seats[c] = seats[c]! + 1;
      assigned++;
      i++;
    }
    final List<String> bySize = order.toList()
      ..sort((String a, String b) => seats[b]!.compareTo(seats[a]!));
    int j = 0;
    while (assigned > total) {
      final String c = bySize[j % bySize.length];
      if (seats[c]! > 1) {
        seats[c] = seats[c]! - 1;
        assigned--;
      }
      j++;
    }
    return seats;
  }

  /// Fisher–Yates with an injected [Random], so shuffles are reproducible.
  static void _seededShuffle(List<int> list, Random rng) {
    for (int i = list.length - 1; i > 0; i--) {
      final int j = rng.nextInt(i + 1);
      final int tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
