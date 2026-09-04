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

  /// Free-text search across the whole bank.
  ///
  /// Matches on the question, the official answers, the explanation and the
  /// topic names, because someone half-remembering "the Speaker of the House"
  /// may have read it in any of those places. Every word in [query] must match
  /// somewhere, so extra words narrow rather than widen the result.
  ///
  /// Results are ordered by where the match landed — question text first, then
  /// answers, then everything else — so the most likely hit is at the top.
  List<Question> search(String query) {
    final List<String> terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((String t) => t.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) return const <Question>[];

    final List<(int rank, Question q)> hits = <(int, Question)>[];
    for (final Question q in questions) {
      final String inQuestion = q.question.toLowerCase();
      final String inAnswers = q.correctAnswers.join(' ').toLowerCase();
      final String rest =
          '${q.explanation} ${q.category} ${q.subcategory} ${q.distractors.join(' ')}'
              .toLowerCase();
      final String all = '$inQuestion $inAnswers $rest';

      if (!terms.every(all.contains)) continue;
      hits.add((
        terms.every(inQuestion.contains)
            ? 0
            : terms.every(inAnswers.contains)
                ? 1
                : 2,
        q,
      ));
    }

    hits.sort(((int, Question) a, (int, Question) b) {
      final int byRank = a.$1.compareTo(b.$1);
      return byRank != 0 ? byRank : a.$2.id.compareTo(b.$2.id);
    });
    return <Question>[for (final (int, Question) h in hits) h.$2];
  }

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
