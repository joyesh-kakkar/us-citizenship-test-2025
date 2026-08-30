import 'package:flutter/foundation.dart';

import 'question.dart';
import 'quiz_meta.dart';
import 'scope.dart';

/// The whole bundled question bank: [meta] plus every [Question], with the
/// lookups the UI needs.
///
/// [fromJson] validates the structural invariants the app relies on and throws
/// a [FormatException] rather than letting a malformed bank reach the UI.
@immutable
class QuestionBank {
  QuestionBank({required this.meta, required List<Question> questions})
      : questions = List<Question>.unmodifiable(questions),
        _byId = Map<int, Question>.unmodifiable(<int, Question>{
          for (final Question q in questions) q.id: q,
        });

  final QuizMeta meta;
  final List<Question> questions;
  final Map<int, Question> _byId;

  Question? byId(int id) => _byId[id];

  List<Question> byIds(Iterable<int> ids) =>
      ids.map(byId).whereType<Question>().toList(growable: false);

  /// The 20 questions in the 65/20 accommodation set.
  List<Question> get starredQuestions =>
      questions.where((Question q) => q.starred).toList(growable: false);

  List<Question> inScope(StudyScope scope) => switch (scope) {
        StudyScope.all => questions,
        StudyScope.starred => starredQuestions,
      };

  /// Categories in the order they first appear in the bank.
  List<String> get categories => _distinct(questions.map((Question q) => q.category));

  List<String> subcategoriesOf(String category) => _distinct(questions
      .where((Question q) => q.category == category)
      .map((Question q) => q.subcategory));

  List<Question> questionsIn(String category, String subcategory) => questions
      .where((Question q) => q.category == category && q.subcategory == subcategory)
      .toList(growable: false);

  int countIn(String category) =>
      questions.where((Question q) => q.category == category).length;

  static List<String> _distinct(Iterable<String> values) {
    final Set<String> seen = <String>{};
    return <String>[
      for (final String v in values)
        if (seen.add(v)) v,
    ];
  }

  factory QuestionBank.fromJson(Map<String, dynamic> json) {
    final QuizMeta meta = QuizMeta.fromJson(
      json['meta'] as Map<String, dynamic>? ??
          (throw const FormatException('Question bank has no "meta" block')),
    );

    final List<dynamic> raw = json['questions'] as List<dynamic>? ??
        (throw const FormatException('Question bank has no "questions" list'));

    final List<Question> questions = raw
        .map((dynamic e) => Question.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    // Invariants the rest of the app assumes. Counts come from meta so the
    // numbers are never duplicated in code.
    if (questions.length != meta.totalQuestions) {
      throw FormatException(
        'Question bank has ${questions.length} questions, meta says ${meta.totalQuestions}',
      );
    }
    final Set<int> ids = questions.map((Question q) => q.id).toSet();
    if (ids.length != questions.length) {
      throw const FormatException('Question bank contains duplicate ids');
    }
    final int starred = questions.where((Question q) => q.starred).length;
    if (starred < meta.special6520.asked) {
      throw FormatException(
        'Only $starred starred questions, but a 65/20 test asks ${meta.special6520.asked}',
      );
    }

    return QuestionBank(meta: meta, questions: questions);
  }
}
