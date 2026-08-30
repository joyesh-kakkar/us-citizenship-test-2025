
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/mcq_generator.dart';
import '../models/mcq_item.dart';
import '../models/practice_test.dart';
import '../models/quiz_meta.dart';
import '../models/question.dart';
import '../models/question_bank.dart';
import 'providers.dart';

/// The fixed practice test the runner is currently executing.
///
/// The runner screen wraps itself in a `ProviderScope` that overrides this,
/// which re-creates [testControllerProvider] against the chosen test while
/// everything else stays shared with the parent scope.
final Provider<PracticeTest> activeTestProvider = Provider<PracticeTest>(
  (Ref ref) => throw StateError('activeTestProvider must be overridden per test run'),
);

/// One graded test run: a fixed set of questions, no feedback until the end,
/// no timer in this MVP.
@immutable
class TestRunState {
  const TestRunState({
    required this.testId,
    required this.title,
    this.items = const <McqItem>[],
    this.answers = const <int?>[],
    this.index = 0,
    this.rule = const PassingRule(asked: 0, needToPass: 0),
    this.finished = false,
    this.justPassedFirstTime = false,
  });

  final String testId;
  final String title;
  final List<McqItem> items;

  /// Selected option per question; null where unanswered.
  final List<int?> answers;

  final int index;

  /// Thresholds for this run, from the test (which took them from `meta`).
  final PassingRule rule;

  final bool finished;

  /// True on the results screen only when this run is the user's first pass of
  /// this test — the cue to request a store review once.
  final bool justPassedFirstTime;

  bool get isEmpty => items.isEmpty;
  int get total => items.length;
  McqItem? get current => index < items.length ? items[index] : null;
  int? get selectedIndex => index < answers.length ? answers[index] : null;
  bool get isLastQuestion => index == items.length - 1;

  int get correctCount {
    int count = 0;
    for (int i = 0; i < items.length; i++) {
      final int? answer = i < answers.length ? answers[i] : null;
      if (answer != null && items[i].isCorrect(answer)) count++;
    }
    return count;
  }

  bool get passed => rule.passes(correctCount);

  /// Items the user got wrong, for the end-of-test review.
  List<McqItem> get missedItems => <McqItem>[
        for (int i = 0; i < items.length; i++)
          if (answers[i] == null || !items[i].isCorrect(answers[i]!)) items[i],
      ];

  TestRunState _copy({
    List<int?>? answers,
    int? index,
    bool? finished,
    bool? justPassedFirstTime,
  }) =>
      TestRunState(
        testId: testId,
        title: title,
        items: items,
        answers: answers ?? this.answers,
        index: index ?? this.index,
        rule: rule,
        finished: finished ?? this.finished,
        justPassedFirstTime: justPassedFirstTime ?? this.justPassedFirstTime,
      );
}

/// Builds and scores one fixed practice test.
class TestController extends Notifier<TestRunState> {
  /// Builds the run immediately so the first question shows on the first frame.
  @override
  TestRunState build() => _draw();

  /// Restarts the same test (a fresh shuffle of options).
  void start() => state = _draw();

  TestRunState _draw() {
    final PracticeTest test = ref.read(activeTestProvider);
    final QuestionBank bank = ref.read(questionBankProvider);

    // Build one item per question id. buildMcq may return null for a volatile
    // question if the config lost its answer since the catalogue was built;
    // such items are simply dropped, and the pass threshold scales to match.
    final List<McqItem> items = <McqItem>[
      for (final int id in test.questionIds)
        if (bank.byId(id) case final Question q)
          ?buildMcq(q, ref.read(remoteConfigProvider).config, rng: ref.read(randomProvider)),
    ];

    final PassingRule rule = items.length == test.questionCount
        ? PassingRule(asked: test.questionCount, needToPass: test.needToPass)
        : PassingRule(
            asked: items.length,
            needToPass: (test.needToPass * items.length / test.questionCount).ceil().clamp(1, items.length),
          );

    return TestRunState(
      testId: test.id,
      title: test.title,
      items: items,
      answers: List<int?>.filled(items.length, null),
      rule: rule,
    );
  }

  /// Selects an option for the current question. Changeable until the user
  /// moves on, so a mis-tap is not punished.
  void select(int optionIndex) {
    if (state.finished || state.current == null) return;
    final List<int?> answers = List<int?>.of(state.answers);
    answers[state.index] = optionIndex;
    state = state._copy(answers: answers);
  }

  /// Advances, or finishes on the last question. Returns a future that
  /// completes once a finished run has recorded its result — the UI ignores it,
  /// tests await it.
  Future<void> next() async {
    if (state.selectedIndex == null) return;
    if (state.isLastQuestion) {
      await _finish();
      return;
    }
    state = state._copy(index: state.index + 1);
  }

  Future<void> _finish() async {
    final int correct = state.correctCount;
    final int total = state.total;
    final bool passed = state.passed;

    // Record every answer toward overall progress, then the test result. The
    // first-ever pass of this test is the peak-goodwill moment for a review.
    final ProgressNotifier progress = ref.read(progressProvider.notifier);
    for (int i = 0; i < state.items.length; i++) {
      final int? answer = state.answers[i];
      await progress.record(
        questionId: state.items[i].question.id,
        correct: answer != null && state.items[i].isCorrect(answer),
      );
    }

    final bool firstPass = await ref.read(testResultsProvider.notifier).recordAttempt(
          testId: state.testId,
          correct: correct,
          total: total,
          passed: passed,
        );

    state = state._copy(finished: true, justPassedFirstTime: firstPass);
  }
}

// Listing [activeTestProvider] as a dependency is what makes the runner's
// nested `ProviderScope` work: overriding the dependency re-scopes this
// provider into that child container, so it reads the overridden test rather
// than the root one (which throws). Without this the controller mounts in the
// root scope and the runner cannot start.
final NotifierProvider<TestController, TestRunState> testControllerProvider =
    NotifierProvider<TestController, TestRunState>(
  TestController.new,
  dependencies: [activeTestProvider],
);
