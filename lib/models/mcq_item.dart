import 'package:flutter/foundation.dart';

import 'question.dart';

/// A ready-to-show multiple-choice item: exactly [kOptionCount] distinct
/// options with exactly one correct.
@immutable
class McqItem {
  McqItem({
    required this.question,
    required List<String> options,
    required this.correctIndex,
  }) : options = List<String>.unmodifiable(options);

  final Question question;

  /// Shuffled option strings, all distinct.
  final List<String> options;

  final int correctIndex;

  /// The option the engine picked as correct. Study still shows every
  /// officially acceptable answer.
  String get correctAnswer => options[correctIndex];

  bool isCorrect(int index) => index == correctIndex;
}
