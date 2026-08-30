import 'dart:math';

import '../config.dart';
import '../models/mcq_item.dart';
import '../models/question.dart';
import '../models/remote_config.dart';

/// Builds multiple-choice items from the question bank.
///
/// Pure and deterministic for a given [Random], so it is fully unit-testable
/// and never touches storage, the network, or Flutter.
///
/// Guarantees for every item returned by [buildMcq]:
///  * exactly [kOptionCount] options,
///  * all options distinct (compared case-insensitively),
///  * `options[correctIndex]` is an officially acceptable answer,
///  * no distractor equals the correct option,
///  * the source lists on [Question] and [RemoteConfig] are never mutated.
///
/// [isQuizzable] and [buildMcq] agree: if [isQuizzable] returns true,
/// [buildMcq] returns a non-null item for any [Random].

/// The answer material an item is built from, after resolving where the
/// correct answers live for this question's [AnswerType].
class _AnswerSources {
  const _AnswerSources(this.correct, this.distractors);

  final List<String> correct;
  final List<String> distractors;
}

/// Whether this question can be shown in Quiz or Test right now.
///
/// False for:
///  * every `variesByState` question (study-only in this MVP), and
///  * `volatile` questions with no usable remote-config entry.
bool isQuizzable(Question question, RemoteConfig config) =>
    _resolveSources(question, config) != null;

/// Builds one item, or returns null if [question] is not quizzable.
McqItem? buildMcq(Question question, RemoteConfig config, {required Random rng}) {
  final _AnswerSources? sources = _resolveSources(question, config);
  if (sources == null) return null;

  final String correct = sources.correct[rng.nextInt(sources.correct.length)];

  // Copy before shuffling so the bank's own lists are never reordered.
  final List<String> wrong = _distinctExcluding(sources.distractors, correct)
    ..shuffle(rng);

  // _resolveSources already guaranteed enough distractors, but stay defensive
  // rather than throwing in front of a user.
  if (wrong.length < kOptionCount - 1) return null;

  final List<String> options = <String>[
    correct,
    ...wrong.take(kOptionCount - 1),
  ]..shuffle(rng);

  return McqItem(
    question: question,
    options: options,
    correctIndex: options.indexOf(correct),
  );
}

/// All quizzable questions from [questions], preserving order.
List<Question> quizzableFrom(Iterable<Question> questions, RemoteConfig config) =>
    questions.where((Question q) => isQuizzable(q, config)).toList(growable: false);

/// Draws [count] questions at random without repeats, for a graded test run.
///
/// Returns fewer than [count] only if the pool itself is smaller.
List<Question> drawQuestions(
  List<Question> pool,
  int count, {
  required Random rng,
}) {
  final List<Question> shuffled = List<Question>.of(pool)..shuffle(rng);
  return shuffled.take(count).toList(growable: false);
}

_AnswerSources? _resolveSources(Question question, RemoteConfig config) {
  switch (question.answerType) {
    case AnswerType.staticAnswer:
      return _validate(question.correctAnswers, question.distractors);

    case AnswerType.volatile:
      // Study-only until a valid remote config supplies the current answer.
      final RemoteAnswerSet? answers = config.answerFor(question.remoteConfigKey);
      if (answers == null || !answers.isUsable) return null;
      return _validate(answers.correct, answers.distractors);

    case AnswerType.variesByState:
      // Phase 2: answer from a per-state dataset keyed on question.stateField,
      // using question.distractorStrategy to build wrong options. Until then
      // these questions are study-only.
      return null;
  }
}

/// Accepts the sources only if *any* correct answer the engine might pick
/// still leaves [kOptionCount] - 1 distinct distractors. That makes
/// [isQuizzable] exact rather than optimistic.
_AnswerSources? _validate(List<String> correct, List<String> distractors) {
  if (correct.isEmpty) return null;
  final Set<String> correctKeys = correct.map(_key).toSet();
  final Set<String> seen = <String>{};
  int usable = 0;
  for (final String d in distractors) {
    final String key = _key(d);
    if (correctKeys.contains(key)) continue;
    if (seen.add(key)) usable++;
  }
  if (usable < kOptionCount - 1) return null;
  return _AnswerSources(correct, distractors);
}

/// Distractors distinct from each other and from [correct], order preserved.
List<String> _distinctExcluding(List<String> distractors, String correct) {
  final String correctKey = _key(correct);
  final Set<String> seen = <String>{};
  final List<String> result = <String>[];
  for (final String d in distractors) {
    final String key = _key(d);
    if (key == correctKey) continue;
    if (seen.add(key)) result.add(d);
  }
  return result;
}

/// Options must be distinct as the user perceives them, so compare
/// case-insensitively and ignore surrounding whitespace.
String _key(String value) => value.trim().toLowerCase();
