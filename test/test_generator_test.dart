import 'package:civics_test_app/config.dart';
import 'package:civics_test_app/engine/test_generator.dart';
import 'package:civics_test_app/models/practice_test.dart';
import 'package:civics_test_app/models/question.dart';
import 'package:civics_test_app/models/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// The deterministic practice-test catalogue: the guarantee the app leans on
/// is that "Test 5" is the same 20 questions on every device and every launch.
void main() {
  late QuestionBank bank;

  setUpAll(() async {
    bank = await loadRealBank();
  });

  List<int> ids(PracticeTest t) => t.questionIds;

  group('determinism', () {
    test('the same seed produces byte-identical tests', () {
      final List<PracticeTest> a = TestGenerator.generateNumbered(bank);
      final List<PracticeTest> b = TestGenerator.generateNumbered(bank);

      expect(a.length, b.length);
      for (int i = 0; i < a.length; i++) {
        expect(a[i].id, b[i].id);
        expect(ids(a[i]), ids(b[i]),
            reason: 'test ${i + 1} differed between two generations');
      }
    });

    test('the starred track is stable across generations', () {
      expect(
        ids(TestGenerator.generateStarredTrack(bank)),
        ids(TestGenerator.generateStarredTrack(bank)),
      );
    });

    test('a different seed produces a different catalogue', () {
      final List<PracticeTest> a = TestGenerator.generateNumbered(bank, seed: 1);
      final List<PracticeTest> b = TestGenerator.generateNumbered(bank, seed: 2);
      // Not every test must differ, but the catalogue as a whole must.
      final bool anyDifferent = <int>[
        for (int i = 0; i < a.length; i++)
          if (!_listEquals(ids(a[i]), ids(b[i]))) i,
      ].isNotEmpty;
      expect(anyDifferent, isTrue);
    });
  });

  group('the numbered catalogue', () {
    late List<PracticeTest> tests;
    setUpAll(() => tests = TestGenerator.generateNumbered(bank));

    test('has exactly the configured number of tests', () {
      expect(tests, hasLength(kPracticeTestCount));
    });

    test('each test has the standard size and threshold from meta', () {
      for (final PracticeTest t in tests) {
        expect(t.questionCount, bank.meta.standard.asked);
        expect(t.needToPass, bank.meta.standard.needToPass);
        expect(t.premium, isFalse, reason: 'nothing is gated in this MVP');
        expect(t.isStarredTrack, isFalse);
      }
    });

    test('never repeats a question within one test', () {
      for (final PracticeTest t in tests) {
        expect(ids(t).toSet(), hasLength(t.questionCount),
            reason: '${t.title} repeats a question');
      }
    });

    test('never includes a variesByState question', () {
      final Set<int> varies = bank.questions
          .where((Question q) => q.answerType == AnswerType.variesByState)
          .map((Question q) => q.id)
          .toSet();
      for (final PracticeTest t in tests) {
        expect(ids(t).toSet().intersection(varies), isEmpty,
            reason: '${t.title} contains a study-only question');
      }
    });

    test('covers all three categories in every test', () {
      String catOf(int id) => bank.byId(id)!.category;
      for (final PracticeTest t in tests) {
        final Set<String> cats = ids(t).map(catOf).toSet();
        expect(cats, hasLength(3), reason: '${t.title} misses a category');
      }
    });

    test('leans toward the largest category, proportionally', () {
      // American Government is the biggest slice of the bank, so on average a
      // test should ask more from it than from Symbols and Holidays.
      String catOf(int id) => bank.byId(id)!.category;
      int fromGov = 0;
      int fromSymbols = 0;
      for (final PracticeTest t in tests) {
        for (final int id in ids(t)) {
          final String c = catOf(id);
          if (c == 'American Government') fromGov++;
          if (c == 'Symbols and Holidays') fromSymbols++;
        }
      }
      expect(fromGov, greaterThan(fromSymbols));
    });

    test('spreads coverage across the bank rather than reusing a few', () {
      final Set<int> used = <int>{for (final PracticeTest t in tests) ...ids(t)};
      // 20 tests × 20 questions from a ~124 eligible pool should touch most of
      // the bank, not a small clump.
      expect(used.length, greaterThan(100));
    });
  });

  group('the starred track', () {
    test('is the 65/20 size and threshold, from starred questions only', () {
      final PracticeTest track = TestGenerator.generateStarredTrack(bank);

      expect(track.questionCount, bank.meta.special6520.asked);
      expect(track.needToPass, bank.meta.special6520.needToPass);
      expect(track.isStarredTrack, isTrue);
      for (final int id in track.questionIds) {
        final Question q = bank.byId(id)!;
        expect(q.starred, isTrue);
        expect(q.answerType, isNot(AnswerType.variesByState));
      }
      expect(track.questionIds.toSet(), hasLength(track.questionCount));
    });
  });

  test('generate() returns the numbered tests plus the starred track', () {
    final List<PracticeTest> all = TestGenerator.generate(bank);
    expect(all, hasLength(kPracticeTestCount + 1));
    expect(all.last.isStarredTrack, isTrue);
  });
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
