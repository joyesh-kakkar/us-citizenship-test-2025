import 'package:flutter/foundation.dart';

/// Locally stored study progress. Never leaves the device.
@immutable
class Progress {
  Progress({
    required Set<int> everCorrectIds,
    required Set<int> missedIds,
    required this.quizAnswered,
    required this.quizCorrect,
  })  : everCorrectIds = Set<int>.unmodifiable(everCorrectIds),
        missedIds = Set<int>.unmodifiable(missedIds);

  const Progress.empty()
      : everCorrectIds = const <int>{},
        missedIds = const <int>{},
        quizAnswered = 0,
        quizCorrect = 0;

  /// Questions answered correctly at least once, ever.
  final Set<int> everCorrectIds;

  /// Questions missed and not since answered correctly.
  final Set<int> missedIds;

  final int quizAnswered;
  final int quizCorrect;

  /// Records one answer. A correct answer clears the question from [missedIds]
  /// so "needs work" always reflects current standing.
  Progress recordAnswer({required int questionId, required bool correct}) {
    final Set<int> ever = Set<int>.of(everCorrectIds);
    final Set<int> missed = Set<int>.of(missedIds);
    if (correct) {
      ever.add(questionId);
      missed.remove(questionId);
    } else {
      missed.add(questionId);
    }
    return Progress(
      everCorrectIds: ever,
      missedIds: missed,
      quizAnswered: quizAnswered + 1,
      quizCorrect: quizCorrect + (correct ? 1 : 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Progress &&
      other.quizAnswered == quizAnswered &&
      other.quizCorrect == quizCorrect &&
      setEquals(other.everCorrectIds, everCorrectIds) &&
      setEquals(other.missedIds, missedIds);

  @override
  int get hashCode => Object.hash(
        quizAnswered,
        quizCorrect,
        Object.hashAllUnordered(everCorrectIds),
        Object.hashAllUnordered(missedIds),
      );
}
