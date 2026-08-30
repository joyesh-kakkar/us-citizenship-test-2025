import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config.dart';

/// The answers for one volatile question, as supplied by remote config.
@immutable
class RemoteAnswerSet {
  RemoteAnswerSet({required List<String> correct, required List<String> distractors})
      : correct = List<String>.unmodifiable(correct),
        distractors = List<String>.unmodifiable(distractors);

  final List<String> correct;
  final List<String> distractors;

  /// Whether this entry can back a multiple-choice item. Empty arrays are a
  /// valid, expected state: the question simply stays study-only.
  bool get isUsable => correct.isNotEmpty && distractors.length >= kOptionCount - 1;

  /// Returns null instead of throwing so one malformed entry never
  /// invalidates the whole document.
  static RemoteAnswerSet? tryParse(Object? node) {
    if (node is! Map<String, dynamic>) return null;
    final List<String>? correct = _stringList(node['correct']);
    final List<String>? distractors = _stringList(node['distractors']);
    if (correct == null || distractors == null) return null;
    return RemoteAnswerSet(correct: correct, distractors: distractors);
  }

  static List<String>? _stringList(Object? value) {
    if (value == null) return const <String>[];
    if (value is! List) return null;
    if (value.any((Object? e) => e is! String)) return null;
    return value.cast<String>();
  }
}

/// Answers that change with elections and appointments, kept outside the app
/// binary so they can be updated without a release.
@immutable
class RemoteConfig {
  RemoteConfig({
    required this.version,
    required this.updatedAt,
    required Map<String, RemoteAnswerSet> answers,
  }) : answers = Map<String, RemoteAnswerSet>.unmodifiable(answers);

  /// A config with no answers at all: every volatile question is study-only.
  const RemoteConfig.empty()
      : version = 'none',
        updatedAt = 'never',
        answers = const <String, RemoteAnswerSet>{};

  final String version;
  final String updatedAt;
  final Map<String, RemoteAnswerSet> answers;

  RemoteAnswerSet? answerFor(String? key) => key == null ? null : answers[key];

  /// How many volatile questions this config can actually make quizzable.
  int get usableAnswerCount =>
      answers.values.where((RemoteAnswerSet a) => a.isUsable).length;

  /// Parses and validates a config document.
  ///
  /// Returns null when the document is unusable as a whole (not JSON, not an
  /// object, or missing an `answers` map). Individual malformed entries are
  /// dropped rather than failing the parse.
  static RemoteConfig? tryParse(String jsonText) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    final Object? rawAnswers = decoded['answers'];
    if (rawAnswers is! Map<String, dynamic>) return null;

    final Map<String, RemoteAnswerSet> answers = <String, RemoteAnswerSet>{};
    rawAnswers.forEach((String key, Object? node) {
      final RemoteAnswerSet? parsed = RemoteAnswerSet.tryParse(node);
      if (parsed != null) answers[key] = parsed;
    });

    return RemoteConfig(
      version: decoded['version'] as String? ?? 'unknown',
      updatedAt: decoded['updatedAt'] as String? ?? 'unknown',
      answers: answers,
    );
  }
}
