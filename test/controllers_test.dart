import 'package:civics_test_app/engine/test_generator.dart';
import 'package:civics_test_app/models/mcq_item.dart';
import 'package:civics_test_app/models/practice_test.dart';
import 'package:civics_test_app/models/progress.dart';
import 'package:civics_test_app/models/question.dart';
import 'package:civics_test_app/models/remote_config.dart';
import 'package:civics_test_app/models/scope.dart';
import 'package:civics_test_app/state/providers.dart';
import 'package:civics_test_app/state/quiz_controller.dart';
import 'package:civics_test_app/state/test_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  setUpAll(primeAssets);

  Future<ProviderContainer> makeContainer({
    RemoteConfig? config,
    int seed = 1,
    PracticeTest? activeTest,
  }) async {
    final ProviderContainer container =
        await testContainer(config: config, seed: seed, activeTest: activeTest);
    addTearDown(container.dispose);
    return container;
  }

  group('scoped pool', () {
    test('excludes variesByState questions from the all-questions scope', () async {
      final ProviderContainer container = await makeContainer();
      final List<Question> pool = container.read(scopedPoolProvider);

      expect(pool, hasLength(124));
      expect(
        pool.any((Question q) => q.answerType == AnswerType.variesByState),
        isFalse,
      );
    });

    test('narrows to starred questions when the scope changes', () async {
      final ProviderContainer container = await makeContainer();
      await container.read(scopeProvider.notifier).set(StudyScope.starred);

      final List<Question> pool = container.read(scopedPoolProvider);

      expect(pool.every((Question q) => q.starred), isTrue);
      expect(pool, hasLength(19), reason: '20 starred less the one that varies by state');
    });

    test('drops volatile questions when no config is available', () async {
      final ProviderContainer container =
          await makeContainer(config: const RemoteConfig.empty());

      expect(container.read(scopedPoolProvider), hasLength(120));
      expect(container.read(studyOnlyCountProvider), 8);
    });
  });

  group('quiz', () {
    test('serves an item and scores a correct answer', () async {
      final ProviderContainer container = await makeContainer();
      final QuizController quiz = container.read(quizControllerProvider.notifier);
      quiz.start();

      final McqItem item = container.read(quizControllerProvider).item!;
      quiz.answer(item.correctIndex);

      final QuizState state = container.read(quizControllerProvider);
      expect(state.hasAnswered, isTrue);
      expect(state.isCorrect, isTrue);
      expect(state.correct, 1);
      expect(state.answered, 1);
      expect(container.read(progressProvider).everCorrectIds, contains(item.question.id));
    });

    test('records a wrong answer for review without ending the session', () async {
      final ProviderContainer container = await makeContainer();
      final QuizController quiz = container.read(quizControllerProvider.notifier);
      quiz.start();

      final McqItem item = container.read(quizControllerProvider).item!;
      quiz.answer((item.correctIndex + 1) % item.options.length);

      final Progress progress = container.read(progressProvider);
      expect(container.read(quizControllerProvider).isCorrect, isFalse);
      expect(progress.missedIds, contains(item.question.id));
      expect(progress.everCorrectIds, isNot(contains(item.question.id)));
    });

    test('ignores a second tap on the same question', () async {
      final ProviderContainer container = await makeContainer();
      final QuizController quiz = container.read(quizControllerProvider.notifier);
      quiz.start();

      final McqItem item = container.read(quizControllerProvider).item!;
      quiz.answer(item.correctIndex);
      quiz.answer((item.correctIndex + 1) % item.options.length);

      final QuizState state = container.read(quizControllerProvider);
      expect(state.answered, 1, reason: 'a double tap must not score twice');
      expect(state.isCorrect, isTrue);
    });

    test('keeps the running score across questions and never repeats in a row', () async {
      final ProviderContainer container = await makeContainer();
      final QuizController quiz = container.read(quizControllerProvider.notifier);
      quiz.start();

      int? previousId;
      for (int i = 0; i < 30; i++) {
        final McqItem item = container.read(quizControllerProvider).item!;
        expect(item.question.id, isNot(previousId));
        previousId = item.question.id;
        quiz.answer(item.correctIndex);
        quiz.next();
      }

      final QuizState state = container.read(quizControllerProvider);
      expect(state.answered, 30);
      expect(state.correct, 30);
    });
  });

  group('practice test (fixed catalogue)', () {
    PracticeTest numberedOne() => TestGenerator.generateNumbered(testBank).first;
    PracticeTest starredTrack() => TestGenerator.generateStarredTrack(testBank);

    test('runs a numbered test with the standard thresholds from meta', () async {
      final PracticeTest test = numberedOne();
      final ProviderContainer container = await makeContainer(activeTest: test);

      final TestRunState state = container.read(testControllerProvider);
      expect(state.testId, 'test-1');
      expect(state.rule.asked, 20);
      expect(state.rule.needToPass, 12);
      expect(state.items, hasLength(20));
      expect(
        state.items.map((McqItem i) => i.question.id).toSet(),
        hasLength(20),
        reason: 'a numbered test must not ask the same question twice',
      );
    });

    test('runs the starred track with the 65/20 thresholds', () async {
      final ProviderContainer container = await makeContainer(activeTest: starredTrack());

      final TestRunState state = container.read(testControllerProvider);
      expect(state.rule.asked, 10);
      expect(state.rule.needToPass, 6);
      expect(state.items, hasLength(10));
      expect(state.items.every((McqItem i) => i.question.starred), isTrue);
    });

    test('passing records the result and reports a first-time pass', () async {
      final PracticeTest test = numberedOne();
      final ProviderContainer container = await makeContainer(activeTest: test);
      final TestController runner = container.read(testControllerProvider.notifier);

      for (int i = 0; i < 20; i++) {
        final TestRunState state = container.read(testControllerProvider);
        runner.select(state.current!.correctIndex);
        await runner.next();
      }

      final TestRunState state = container.read(testControllerProvider);
      expect(state.finished, isTrue);
      expect(state.correctCount, 20);
      expect(state.passed, isTrue);
      expect(state.justPassedFirstTime, isTrue);
      expect(container.read(testStatusProvider(test.id)).passed, isTrue);
      expect(container.read(testStatusProvider(test.id)).bestCorrect, 20);
    });

    test('a second pass is not flagged as first-time', () async {
      final PracticeTest test = numberedOne();
      final ProviderContainer container = await makeContainer(activeTest: test);
      final TestController runner = container.read(testControllerProvider.notifier);

      Future<void> playPerfect() async {
        runner.start();
        for (int i = 0; i < 20; i++) {
          final TestRunState s = container.read(testControllerProvider);
          runner.select(s.current!.correctIndex);
          await runner.next();
        }
      }

      await playPerfect();
      expect(container.read(testControllerProvider).justPassedFirstTime, isTrue);
      await playPerfect();
      expect(container.read(testControllerProvider).justPassedFirstTime, isFalse,
          reason: 'the review prompt should fire only on the first pass');
    });

    test('failing lists every missed question and records the misses', () async {
      final PracticeTest test = numberedOne();
      final ProviderContainer container = await makeContainer(activeTest: test);
      final TestController runner = container.read(testControllerProvider.notifier);

      // 11 right, 9 wrong: one short of the 12 needed.
      for (int i = 0; i < 20; i++) {
        final TestRunState state = container.read(testControllerProvider);
        final McqItem item = state.current!;
        runner.select(
          i < 11 ? item.correctIndex : (item.correctIndex + 1) % item.options.length,
        );
        await runner.next();
      }

      final TestRunState state = container.read(testControllerProvider);
      expect(state.correctCount, 11);
      expect(state.passed, isFalse);
      expect(state.missedItems, hasLength(9));
      expect(container.read(progressProvider).missedIds, hasLength(9));
      expect(container.read(testStatusProvider(test.id)).passed, isFalse);
    });

    test('lets the user change an answer before moving on', () async {
      final ProviderContainer container = await makeContainer(activeTest: numberedOne());
      final TestController runner = container.read(testControllerProvider.notifier);

      final McqItem item = container.read(testControllerProvider).current!;
      runner.select((item.correctIndex + 1) % item.options.length);
      runner.select(item.correctIndex);
      await runner.next();

      final TestRunState state = container.read(testControllerProvider);
      expect(state.index, 1);
      expect(state.answers.first, item.correctIndex);
    });

    test('will not advance until something is selected', () async {
      final ProviderContainer container = await makeContainer(activeTest: numberedOne());
      final TestController runner = container.read(testControllerProvider.notifier);

      await runner.next();

      expect(container.read(testControllerProvider).index, 0);
      expect(container.read(testControllerProvider).finished, isFalse);
    });

    test('drops an unquizzable volatile question and scales the threshold', () async {
      // A hand-built test whose 4th question is volatile; with no config it
      // cannot be built, so the run has 3 items and a scaled pass mark.
      const PracticeTest test = PracticeTest(
        id: 'custom',
        title: 'Custom',
        questionIds: <int>[1, 2, 3, 30],
        needToPass: 3,
      );
      final ProviderContainer container = await makeContainer(
        config: const RemoteConfig.empty(),
        activeTest: test,
      );

      final TestRunState state = container.read(testControllerProvider);
      expect(state.items, hasLength(3), reason: 'the volatile question is dropped');
      expect(state.items.every((McqItem i) => i.question.answerType == AnswerType.staticAnswer),
          isTrue);
      expect(state.rule.needToPass, lessThanOrEqualTo(3));
    });
  });

}
