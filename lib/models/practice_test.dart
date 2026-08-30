import 'package:flutter/foundation.dart';

/// One fixed, numbered practice test: a stable set of question ids with a pass
/// threshold, mirroring the real exam's pools.
///
/// [premium] is the seam for a future paywall. It is `false` on every test in
/// this MVP and is ignored while the entitlements provider unlocks everything,
/// so gating can be added later without touching this model's callers.
@immutable
class PracticeTest {
  const PracticeTest({
    required this.id,
    required this.title,
    required this.questionIds,
    required this.needToPass,
    this.isStarredTrack = false,
    this.premium = false,
  });

  /// Stable id, e.g. `test-3` or `starred`.
  final String id;
  final String title;

  /// The exact questions this test asks, in order. Stable across launches.
  final List<int> questionIds;

  final int needToPass;

  /// The 65/20 accommodation track (10 questions from the starred set).
  final bool isStarredTrack;

  /// Reserved for Phase-2 monetization; always false here.
  final bool premium;

  int get questionCount => questionIds.length;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'questionIds': questionIds,
        'needToPass': needToPass,
        'isStarredTrack': isStarredTrack,
        'premium': premium,
      };

  factory PracticeTest.fromJson(Map<String, dynamic> json) => PracticeTest(
        id: json['id'] as String,
        title: json['title'] as String,
        questionIds:
            (json['questionIds'] as List<dynamic>).map((dynamic e) => e as int).toList(),
        needToPass: json['needToPass'] as int,
        isStarredTrack: json['isStarredTrack'] as bool? ?? false,
        premium: json['premium'] as bool? ?? false,
      );
}

/// A user's standing on one practice test.
@immutable
class TestStatus {
  const TestStatus({this.bestCorrect, this.total, this.passed = false});

  const TestStatus.notStarted()
      : bestCorrect = null,
        total = null,
        passed = false;

  /// Best number correct so far, or null if never attempted.
  final int? bestCorrect;
  final int? total;
  final bool passed;

  bool get attempted => bestCorrect != null;

  int get bestPercent =>
      (bestCorrect == null || total == null || total == 0)
          ? 0
          : ((bestCorrect! / total!) * 100).round();

  /// Merges a new attempt, keeping the best score and a sticky "passed".
  TestStatus merge({required int correct, required int total, required bool passed}) {
    final bool better = bestCorrect == null || correct > bestCorrect!;
    return TestStatus(
      bestCorrect: better ? correct : bestCorrect,
      total: better ? total : this.total,
      passed: this.passed || passed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bestCorrect': bestCorrect,
        'total': total,
        'passed': passed,
      };

  factory TestStatus.fromJson(Map<String, dynamic> json) => TestStatus(
        bestCorrect: json['bestCorrect'] as int?,
        total: json['total'] as int?,
        passed: json['passed'] as bool? ?? false,
      );
}
