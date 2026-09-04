import 'package:civics_test_app/engine/test_generator.dart';
import 'package:civics_test_app/models/mcq_item.dart';
import 'package:civics_test_app/models/practice_test.dart';
import 'package:civics_test_app/models/progress.dart';
import 'package:civics_test_app/models/question_bank.dart';
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

    test('a double-tap on the final question grades the run only once', () async {
      final ProviderContainer setup = await makeContainer();
      final PracticeTest test = setup.read(numberedTestsProvider).first;

      final ProviderContainer container = await makeContainer(activeTest: test);
      final TestController controller = container.read(testControllerProvider.notifier);

      while (!container.read(testControllerProvider).isLastQuestion) {
        controller.select(0);
        await controller.next();
      }
      controller.select(0);

      // Two taps in flight at once, exactly like a double-tap on the
      // "Finish and see results" button while it is still enabled.
      await Future.wait<void>(<Future<void>>[controller.next(), controller.next()]);

      final TestRunState state = container.read(testControllerProvider);
      expect(state.finished, isTrue);
      expect(
        container.read(progressProvider).quizAnswered,
        state.total,
        reason: 'each answer must count once, not twice',
      );
    });
  });

  group('weakest topic', () {
    test('offers a topic even before anything has been answered', () async {
      final ProviderContainer container = await makeContainer();
      // With zero progress every category sits at 0, so the first one wins
      // rather than the user being offered nothing at all.
      expect(container.read(weakestCategoryProvider), isNotNull);
    });

    test('is null once every question has been answered correctly', () async {
      final ProviderContainer container = await makeContainer();
      final QuestionBank bank = container.read(questionBankProvider);
      await container.read(progressProvider.notifier).recordAll(
            <({int questionId, bool correct})>[
              for (final Question q in bank.questions)
                (questionId: q.id, correct: true),
            ],
          );

      expect(
        container.read(weakestCategoryProvider),
        isNull,
        reason: 'nothing left to target means no nagging button',
      );
    });

    test('points at the category with the least covered', () async {
      final ProviderContainer container = await makeContainer();
      final MasterySnapshot mastery = container.read(masteryProvider);
      final String? weakest = container.read(weakestCategoryProvider);

      expect(weakest, isNotNull);
      final (int known, int total) = mastery.perCategory[weakest]!;
      final double worst = known / total;
      for (final MapEntry<String, (int, int)> e in mastery.perCategory.entries) {
        if (e.value.$2 == 0 || e.value.$1 >= e.value.$2) continue;
        expect(e.value.$1 / e.value.$2, greaterThanOrEqualTo(worst));
      }
    });

    test('a topic pool holds only that category and is quizzable', () async {
      final ProviderContainer container = await makeContainer();
      const String category = 'American Government';
      final List<Question> pool = container.read(categoryPoolProvider(category));

      expect(pool, isNotEmpty);
      expect(pool.every((Question q) => q.category == category), isTrue);
      expect(
        pool.every((Question q) => q.answerType != AnswerType.variesByState),
        isTrue,
      );
    });
  });

  group('resuming an interrupted test', () {
    test('a part-finished run is restored with its answers and position', () async {
      final ProviderContainer setup = await makeContainer();
      final PracticeTest test = setup.read(numberedTestsProvider).first;
      final TestDeps deps = await resolveDeps();

      // First sitting: answer three questions, then walk away.
      final ProviderContainer first = containerFor(deps, activeTest: test);
      final TestController controller = first.read(testControllerProvider.notifier);
      for (int i = 0; i < 3; i++) {
        controller.select(1);
        await controller.next();
      }
      final TestRunState left = first.read(testControllerProvider);
      first.dispose();

      // Second sitting: same prefs, same test.
      final ProviderContainer second = containerFor(deps, activeTest: test);
      addTearDown(second.dispose);
      final TestRunState resumed = second.read(testControllerProvider);

      expect(resumed.index, left.index, reason: 'picks up on the same question');
      expect(resumed.answers.take(3), everyElement(equals(1)));
      expect(resumed.total, left.total);
      expect(
        <String>[for (final McqItem i in resumed.items) i.options.join('|')],
        <String>[for (final McqItem i in left.items) i.options.join('|')],
        reason: 'options must not be reshuffled underneath a resumed run',
      );
    });

    test('rapid taps still persist the final position, not an earlier one',
        () async {
      final ProviderContainer setup = await makeContainer();
      final PracticeTest test = setup.read(numberedTestsProvider).first;
      final TestDeps deps = await resolveDeps();

      final ProviderContainer first = containerFor(deps, activeTest: test);
      final TestController controller = first.read(testControllerProvider.notifier);

      // Select and advance without awaiting between them, the way a fast
      // tapper drives the screen. Writes must land in order.
      controller.select(1);
      final Future<void> a = controller.next();
      controller.select(2);
      final Future<void> b = controller.next();
      await Future.wait<void>(<Future<void>>[a, b]);
      final int reached = first.read(testControllerProvider).index;
      // Let the queued writes drain before tearing the container down.
      await first.read(testControllerProvider.notifier).flushWrites();
      first.dispose();

      final ProviderContainer second = containerFor(deps, activeTest: test);
      addTearDown(second.dispose);
      expect(second.read(testControllerProvider).index, reached);
    });

    test('a different test does not pick up the saved run', () async {
      final ProviderContainer setup = await makeContainer();
      final List<PracticeTest> tests = setup.read(numberedTestsProvider);
      final TestDeps deps = await resolveDeps();

      final ProviderContainer first = containerFor(deps, activeTest: tests[0]);
      first.read(testControllerProvider.notifier).select(1);
      await first.read(testControllerProvider.notifier).next();
      first.dispose();

      final ProviderContainer second = containerFor(deps, activeTest: tests[1]);
      addTearDown(second.dispose);

      expect(second.read(testControllerProvider).index, 0);
      expect(
        second.read(testControllerProvider).answers,
        everyElement(isNull),
        reason: 'test 2 must start clean even though test 1 was left unfinished',
      );
    });

    test('finishing clears the saved run', () async {
      final ProviderContainer setup = await makeContainer();
      final PracticeTest test = setup.read(numberedTestsProvider).first;
      final TestDeps deps = await resolveDeps();

      final ProviderContainer first = containerFor(deps, activeTest: test);
      final TestController controller = first.read(testControllerProvider.notifier);
      while (!first.read(testControllerProvider).isLastQuestion) {
        controller.select(0);
        await controller.next();
      }
      controller.select(0);
      await controller.next();
      expect(first.read(testControllerProvider).finished, isTrue);
      first.dispose();

      final ProviderContainer second = containerFor(deps, activeTest: test);
      addTearDown(second.dispose);

      expect(second.read(resumableTestProvider), isNull);
      expect(second.read(testControllerProvider).index, 0);
      expect(second.read(testControllerProvider).answers, everyElement(isNull));
    });

    test('abandoning clears the saved run', () async {
      final ProviderContainer setup = await makeContainer();
      final PracticeTest test = setup.read(numberedTestsProvider).first;
      final TestDeps deps = await resolveDeps();

      final ProviderContainer first = containerFor(deps, activeTest: test);
      first.read(testControllerProvider.notifier).select(1);
      await first.read(testControllerProvider.notifier).next();
      expect(first.read(resumableTestProvider), test.id);
      await first.read(testControllerProvider.notifier).abandon();
      first.dispose();

      final ProviderContainer second = containerFor(deps, activeTest: test);
      addTearDown(second.dispose);
      expect(second.read(resumableTestProvider), isNull);
      expect(second.read(testControllerProvider).answers, everyElement(isNull));
    });
  });

  group('scoped quiz pools', () {
    test('an overriding ProviderScope actually drives the quiz controller', () async {
      final ProviderContainer root = await makeContainer();
      final List<Question> onlyOne = <Question>[root.read(quizzablePoolProvider).first];

      // Mirrors what FixMissesScreen and the Favorites quiz do: a child scope
      // that overrides the pool. The controller must draw from that pool.
      final ProviderContainer scoped = ProviderContainer(
        parent: root,
        overrides: [quizPoolProvider.overrideWithValue(onlyOne)],
      );
      addTearDown(scoped.dispose);

      expect(
        scoped.read(quizControllerProvider).item?.question.id,
        onlyOne.single.id,
        reason: 'the controller must respect the overridden pool, not the root one',
      );
    });
  });
}
