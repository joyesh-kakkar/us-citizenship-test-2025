import 'package:flutter/foundation.dart';

/// How a question's correct answers are sourced.
enum AnswerType {
  /// Answers are baked into the bundled question bank.
  staticAnswer('static'),

  /// Answers change with elections/appointments and come from remote config.
  volatile('volatile'),

  /// Answers depend on the applicant's state. Study-only in this MVP.
  variesByState('variesByState');

  const AnswerType(this.wireName);

  final String wireName;

  static AnswerType fromWire(String value) => AnswerType.values.firstWhere(
        (AnswerType t) => t.wireName == value,
        orElse: () => throw FormatException('Unknown answerType "$value"'),
      );
}

/// One civics question exactly as published by USCIS, plus MCQ distractors
/// authored for this app.
///
/// [correctAnswers] and [distractors] are unmodifiable so that the MCQ engine
/// physically cannot mutate the shared question bank.
@immutable
class Question {
  Question({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.question,
    required this.type,
    required this.starred,
    required this.answerType,
    required List<String> correctAnswers,
    required List<String> distractors,
    required this.explanation,
    this.remoteConfigKey,
    this.stateField,
    this.distractorStrategy,
  })  : correctAnswers = List<String>.unmodifiable(correctAnswers),
        distractors = List<String>.unmodifiable(distractors);

  final int id;
  final String category;
  final String subcategory;

  /// The official question wording. Always rendered verbatim.
  final String question;

  /// Content hint from the bank ("numeric", "person", "list", ...). Used only
  /// for small presentation touches, never to alter answer text.
  final String type;

  /// One of the 20 questions in the 65/20 accommodation set.
  final bool starred;

  final AnswerType answerType;

  /// Every officially acceptable answer. Rendered verbatim in Study.
  final List<String> correctAnswers;

  /// Plausible wrong options authored for this app — not official USCIS text.
  final List<String> distractors;

  final String explanation;

  /// Key into the remote config. Present only when [answerType] is volatile.
  final String? remoteConfigKey;

  /// Which per-state field answers this. Present only when [answerType] is
  /// variesByState. Unused in this MVP; the seam for Phase-2 state support.
  final String? stateField;

  /// How to build distractors for a per-state answer (Phase 2).
  final String? distractorStrategy;

  /// True when the answer is not fixed and the Study screen should show a note.
  bool get hasChangingAnswer => answerType != AnswerType.staticAnswer;

  /// "Name five." style questions have many correct answers but an MCQ can
  /// only offer one, so the UI adds a short "choose one" hint.
  bool get expectsMultipleInRealTest => type == 'list';

  factory Question.fromJson(Map<String, dynamic> json) {
    T require<T>(String key) {
      final Object? value = json[key];
      if (value is! T) {
        throw FormatException(
          'Question ${json['id']}: field "$key" is ${value.runtimeType}, expected $T',
        );
      }
      return value;
    }

    List<String> stringList(String key) => switch (json[key]) {
          final List<dynamic> list => list.map((dynamic e) => e as String).toList(),
          null => const <String>[],
          _ => throw FormatException('Question ${json['id']}: "$key" must be a list'),
        };

    return Question(
      id: require<int>('id'),
      category: require<String>('category'),
      subcategory: require<String>('subcategory'),
      question: require<String>('question'),
      type: require<String>('type'),
      starred: require<bool>('starred'),
      answerType: AnswerType.fromWire(require<String>('answerType')),
      correctAnswers: stringList('correctAnswers'),
      distractors: stringList('distractors'),
      explanation: require<String>('explanation'),
      remoteConfigKey: json['remoteConfigKey'] as String?,
      stateField: json['stateField'] as String?,
      distractorStrategy: json['distractorStrategy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is Question && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Question($id)';
}
