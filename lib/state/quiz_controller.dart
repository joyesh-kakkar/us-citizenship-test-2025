import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/mcq_generator.dart';
import '../models/mcq_item.dart';
import '../models/question.dart';
import 'providers.dart';

/// One endless practice session.
@immutable
class QuizState {
  const QuizState({
    this.item,
    this.selectedIndex,
    this.answered = 0,
    this.correct = 0,
  });

  /// The item on screen. Null only if the scoped pool is empty.
  final McqItem? item;

  /// Which option the user tapped, or null if they have not answered yet.
  final int? selectedIndex;

  final int answered;
  final int correct;

  bool get hasAnswered => selectedIndex != null;
  bool get isCorrect => item != null && selectedIndex != null && item!.isCorrect(selectedIndex!);

  QuizState copyWith({
    McqItem? item,
    int? selectedIndex,
    bool clearSelection = false,
    int? answered,
    int? correct,
  }) =>
      QuizState(
        item: item ?? this.item,
        selectedIndex: clearSelection ? null : (selectedIndex ?? this.selectedIndex),
        answered: answered ?? this.answered,
        correct: correct ?? this.correct,
      );
}

/// The pool the quiz draws from. Defaults to the scoped All/Starred pool.
///
/// Entry points that quiz a different set — Fix-your-misses, Favorites — wrap
/// their screen in a `ProviderScope` overriding this, which re-creates
/// [quizControllerProvider] within that scope against the new pool. Progress
/// and everything else stay shared with the parent scope.
final Provider<List<Question>> quizPoolProvider =
    Provider<List<Question>>((Ref ref) => ref.watch(scopedPoolProvider));

/// Drives Quiz: draws items from [quizPoolProvider], scores taps, and records
/// progress. Practice is endless, so questions repeat once the pool is
/// exhausted — but never twice in a row.
class QuizController extends Notifier<QuizState> {
  Question? _previous;

  /// Draws the first item immediately, so the screen never renders an empty
  /// frame before the first question appears.
  @override
  QuizState build() => QuizState(item: _draw());

  /// Starts a fresh session, discarding the running score.
  void start() {
    _previous = null;
    state = QuizState(item: _draw());
  }

  /// Records the user's tap and updates progress. Ignored once answered, so a
  /// double-tap cannot score twice.
  void answer(int index) {
    final McqItem? item = state.item;
    if (item == null || state.hasAnswered) return;

    final bool correct = item.isCorrect(index);
    state = state.copyWith(
      selectedIndex: index,
      answered: state.answered + 1,
      correct: state.correct + (correct ? 1 : 0),
    );
    unawaited(
      ref.read(progressProvider.notifier).record(
            questionId: item.question.id,
            correct: correct,
          ),
    );
  }

  void next() {
    state = QuizState(
      item: _draw(),
      answered: state.answered,
      correct: state.correct,
    );
  }

  McqItem? _draw() {
    final List<Question> pool = ref.read(quizPoolProvider);
    if (pool.isEmpty) return null;

    final Random rng = ref.read(randomProvider);
    Question question = pool[rng.nextInt(pool.length)];
    if (pool.length > 1) {
      // Avoid asking the same question twice in a row. Bounded: a pool that
      // somehow held one question many times over would otherwise spin here
      // forever, and repeating a question is a far smaller problem than
      // hanging the UI thread.
      for (int attempt = 0; attempt < 8 && question == _previous; attempt++) {
        question = pool[rng.nextInt(pool.length)];
      }
    }
    _previous = question;
    return buildMcq(question, ref.read(remoteConfigProvider).config, rng: rng);
  }
}

// Listing [quizPoolProvider] as a dependency is what makes the Fix-your-misses
// and Favorites `ProviderScope`s work: overriding the dependency re-scopes this
// provider into that child container, so it draws from the overridden pool
// rather than the root one. Without this the controller mounts in the root
// scope and both entry points silently quiz the full scoped pool instead.
final NotifierProvider<QuizController, QuizState> quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(
  QuizController.new,
  dependencies: [quizPoolProvider],
);
