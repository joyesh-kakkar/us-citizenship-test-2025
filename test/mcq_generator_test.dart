import 'dart:math';

import 'package:civics_test_app/config.dart';
import 'package:civics_test_app/engine/mcq_generator.dart';
import 'package:civics_test_app/models/mcq_item.dart';
import 'package:civics_test_app/models/question.dart';
import 'package:civics_test_app/models/question_bank.dart';
import 'package:civics_test_app/models/remote_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// Case-insensitive key, matching how the engine compares options.
String key(String s) => s.trim().toLowerCase();

void main() {
  group('static questions', () {
    test('produces four distinct options with exactly one correct', () {
      final Question q = staticQuestion();
      final McqItem item = buildMcq(q, RemoteConfig.empty(), rng: Random(1))!;

      expect(item.options, hasLength(kOptionCount));
      expect(item.options.map(key).toSet(), hasLength(kOptionCount));
      expect(q.correctAnswers, contains(item.correctAnswer));
      expect(item.isCorrect(item.correctIndex), isTrue);
    });

    test('never offers the correct answer as a distractor', () {
      // A question whose distractor list overlaps its correct answers.
      final Question q = staticQuestion(
        correctAnswers: <String>['Alpha', 'Beta'],
        distractors: <String>['Alpha', 'beta', 'Gamma', 'Delta', 'Epsilon'],
      );

      for (int seed = 0; seed < 200; seed++) {
        final McqItem item = buildMcq(q, RemoteConfig.empty(), rng: Random(seed))!;
        final List<String> wrong = <String>[
          for (int i = 0; i < item.options.length; i++)
            if (i != item.correctIndex) item.options[i],
        ];
        expect(wrong.map(key), isNot(contains(key(item.correctAnswer))));
        expect(item.options.map(key).toSet(), hasLength(kOptionCount));
      }
    });

    test('picks different correct answers across runs when several exist', () {
      final Question q = staticQuestion(
        correctAnswers: <String>['One', 'Two', 'Three'],
        distractors: <String>['A', 'B', 'C', 'D'],
      );
      final Set<String> seen = <String>{
        for (int seed = 0; seed < 60; seed++)
          buildMcq(q, RemoteConfig.empty(), rng: Random(seed))!.correctAnswer,
      };
      expect(seen.length, greaterThan(1),
          reason: 'a question with several official answers should vary');
    });

    test('shuffles the correct option into every position over many runs', () {
      final Question q = staticQuestion(
        correctAnswers: <String>['Correct'],
        distractors: <String>['A', 'B', 'C', 'D', 'E'],
      );
      final Set<int> positions = <int>{
        for (int seed = 0; seed < 200; seed++)
          buildMcq(q, RemoteConfig.empty(), rng: Random(seed))!.correctIndex,
      };
      expect(positions, <int>{0, 1, 2, 3},
          reason: 'the correct answer must not favour a fixed slot');
    });

    test('is deterministic for a given seed', () {
      final Question q = staticQuestion();
      final McqItem a = buildMcq(q, RemoteConfig.empty(), rng: Random(7))!;
      final McqItem b = buildMcq(q, RemoteConfig.empty(), rng: Random(7))!;
      expect(a.options, b.options);
      expect(a.correctIndex, b.correctIndex);
    });

    test('never mutates the source lists', () {
      final Question q = staticQuestion(
        correctAnswers: <String>['One', 'Two'],
        distractors: <String>['A', 'B', 'C', 'D'],
      );
      final List<String> correctBefore = List<String>.of(q.correctAnswers);
      final List<String> distractorsBefore = List<String>.of(q.distractors);

      for (int seed = 0; seed < 50; seed++) {
        buildMcq(q, RemoteConfig.empty(), rng: Random(seed));
      }

      expect(q.correctAnswers, correctBefore);
      expect(q.distractors, distractorsBefore);
    });

    test('is not quizzable with fewer than three usable distractors', () {
      final Question q = staticQuestion(distractors: <String>['Only', 'Two']);
      expect(isQuizzable(q, RemoteConfig.empty()), isFalse);
      expect(buildMcq(q, RemoteConfig.empty(), rng: Random(0)), isNull);
    });

    test('counts duplicate distractors only once', () {
      final Question q = staticQuestion(
        distractors: <String>['Same', 'same', 'SAME', 'Other'],
      );
      expect(isQuizzable(q, RemoteConfig.empty()), isFalse,
          reason: 'three of those four options are the same answer');
    });
  });

  group('volatile questions', () {
    test('are quizzable when the config supplies a usable answer', () {
      final Question q = volatileQuestion();
      final RemoteConfig config = configWith();

      expect(isQuizzable(q, config), isTrue);
      final McqItem item = buildMcq(q, config, rng: Random(3))!;
      expect(item.options, hasLength(kOptionCount));
      expect(item.correctAnswer, 'Mike Johnson');
    });

    test('are excluded when the config has no entry at all', () {
      final Question q = volatileQuestion();
      expect(isQuizzable(q, RemoteConfig.empty()), isFalse);
      expect(buildMcq(q, RemoteConfig.empty(), rng: Random(0)), isNull);
    });

    test('are excluded when the entry has empty arrays', () {
      // The shipped placeholder shape: valid JSON, no answers yet.
      final RemoteConfig config =
          configWith(correct: const <String>[], distractors: const <String>[]);
      expect(isQuizzable(volatileQuestion(), config), isFalse);
    });

    test('are excluded when the entry has too few distractors', () {
      final RemoteConfig config =
          configWith(distractors: const <String>['Only one', 'Only two']);
      expect(isQuizzable(volatileQuestion(), config), isFalse);
    });

    test('are excluded when the config key does not match', () {
      final RemoteConfig config = configWith(key: 'president');
      expect(isQuizzable(volatileQuestion(key: 'speaker'), config), isFalse);
    });

    test('never mutate the config lists', () {
      final RemoteConfig config = configWith();
      final RemoteAnswerSet entry = config.answers['speaker']!;
      final List<String> before = List<String>.of(entry.distractors);

      for (int seed = 0; seed < 50; seed++) {
        buildMcq(volatileQuestion(), config, rng: Random(seed));
      }

      expect(entry.distractors, before);
    });
  });

  group('variesByState questions', () {
    test('are always excluded in this MVP', () {
      final Question q = variesByStateQuestion();
      // Even a config that happened to carry a matching key must not help:
      // per-state answers are Phase 2.
      expect(isQuizzable(q, configWith(key: 'capital')), isFalse);
      expect(buildMcq(q, configWith(key: 'capital'), rng: Random(0)), isNull);
    });
  });

  group('the real question bank', () {
    late QuestionBank bank;
    late RemoteConfig config;

    setUp(() async {
      bank = await loadRealBank();
      config = await loadRealRemoteConfig();
    });

    test('every quizzable question yields a valid item on every seed', () {
      final List<Question> pool = quizzableFrom(bank.questions, config);
      expect(pool, isNotEmpty);

      for (final Question q in pool) {
        for (int seed = 0; seed < 12; seed++) {
          final McqItem? item = buildMcq(q, config, rng: Random(seed));
          expect(item, isNotNull, reason: 'question ${q.id} failed on seed $seed');
          expect(item!.options, hasLength(kOptionCount),
              reason: 'question ${q.id} on seed $seed');
          expect(item.options.map(key).toSet(), hasLength(kOptionCount),
              reason: 'question ${q.id} produced duplicate options on seed $seed');
          expect(item.correctIndex, inInclusiveRange(0, kOptionCount - 1));

          final List<String> official = q.answerType == AnswerType.staticAnswer
              ? q.correctAnswers
              : config.answerFor(q.remoteConfigKey)!.correct;
          expect(official, contains(item.correctAnswer),
              reason: 'question ${q.id} served a non-official correct answer');
        }
      }
    });

    test('excludes exactly the variesByState questions when config is complete', () {
      final List<Question> excluded = bank.questions
          .where((Question q) => !isQuizzable(q, config))
          .toList();
      expect(
        excluded.map((Question q) => q.answerType).toSet(),
        <AnswerType>{AnswerType.variesByState},
      );
    });

    test('falls back to static-only when no config is available', () {
      final List<Question> pool = quizzableFrom(bank.questions, RemoteConfig.empty());
      expect(
        pool.every((Question q) => q.answerType == AnswerType.staticAnswer),
        isTrue,
      );
      // Both scopes must still hold enough questions for a full test run.
      expect(pool.length, greaterThanOrEqualTo(bank.meta.standard.asked));
      expect(
        pool.where((Question q) => q.starred).length,
        greaterThanOrEqualTo(bank.meta.special6520.asked),
      );
    });

    test('question 81 works despite having 13 correct answers', () {
      final Question q = bank.byId(81)!;
      expect(q.correctAnswers.length, 13);
      final McqItem item = buildMcq(q, config, rng: Random(5))!;
      expect(item.options.map(key).toSet(), hasLength(kOptionCount));
      expect(q.correctAnswers, contains(item.correctAnswer));
    });
  });

  group('drawQuestions', () {
    test('never repeats a question within one run', () {
      final List<Question> pool = <Question>[
        for (int i = 1; i <= 30; i++) staticQuestion(id: i),
      ];
      final List<Question> drawn = drawQuestions(pool, 20, rng: Random(2));
      expect(drawn, hasLength(20));
      expect(drawn.map((Question q) => q.id).toSet(), hasLength(20));
    });

    test('returns the whole pool when it is smaller than the ask', () {
      final List<Question> pool = <Question>[
        for (int i = 1; i <= 5; i++) staticQuestion(id: i),
      ];
      expect(drawQuestions(pool, 20, rng: Random(2)), hasLength(5));
    });

    test('does not reorder the source pool', () {
      final List<Question> pool = <Question>[
        for (int i = 1; i <= 10; i++) staticQuestion(id: i),
      ];
      final List<int> before = pool.map((Question q) => q.id).toList();
      drawQuestions(pool, 5, rng: Random(1));
      expect(pool.map((Question q) => q.id).toList(), before);
    });
  });
}
