import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/mcq_item.dart';
import '../models/question_bank.dart';

/// A practice test the user left part-way through.
///
/// The whole run is stored, options included, rather than a seed: options are
/// drawn from a shared [Random], so a seed could not reproduce them, and a
/// resumed test that silently reshuffled its own options would be worse than
/// no resume at all.
class SavedRun {
  const SavedRun({
    required this.testId,
    required this.items,
    required this.answers,
    required this.index,
  });

  final String testId;
  final List<McqItem> items;
  final List<int?> answers;
  final int index;
}

/// Persists the single in-flight practice test, so leaving mid-test — or a
/// phone call killing the app — does not throw the run away.
class ActiveRunStore {
  ActiveRunStore(this._prefs);

  final SharedPreferences _prefs;

  /// The saved run, or null if there is none or it no longer fits the bank
  /// (the question set changed under it, or the blob is corrupt).
  SavedRun? load(QuestionBank bank) {
    final String? raw = _prefs.getString(PrefsKeys.activeRun);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> rawItems = json['items'] as List<dynamic>;

      final List<McqItem> items = <McqItem>[];
      for (final dynamic e in rawItems) {
        final Map<String, dynamic> m = e as Map<String, dynamic>;
        final int id = m['q'] as int;
        final question = bank.byId(id);
        // A question that no longer exists invalidates the whole run rather
        // than silently shortening it and moving the pass mark.
        if (question == null) return null;
        items.add(McqItem(
          question: question,
          options: (m['o'] as List<dynamic>).cast<String>(),
          correctIndex: m['c'] as int,
        ));
      }

      final List<int?> answers = (json['a'] as List<dynamic>)
          .map((dynamic v) => v as int?)
          .toList(growable: false);
      final int index = json['i'] as int;

      if (items.isEmpty || answers.length != items.length) return null;
      if (index < 0 || index >= items.length) return null;

      return SavedRun(
        testId: json['t'] as String,
        items: items,
        answers: answers,
        index: index,
      );
    } on Object {
      // A corrupt blob degrades to "no saved run", never a crash.
      return null;
    }
  }

  Future<void> save(SavedRun run) => _prefs.setString(
        PrefsKeys.activeRun,
        jsonEncode(<String, dynamic>{
          't': run.testId,
          'i': run.index,
          'a': run.answers,
          'items': <Map<String, dynamic>>[
            for (final McqItem item in run.items)
              <String, dynamic>{
                'q': item.question.id,
                'o': item.options,
                'c': item.correctIndex,
              },
          ],
        }),
      );

  Future<void> clear() => _prefs.remove(PrefsKeys.activeRun);

  /// The id of the saved run's test, without rebuilding the items — enough for
  /// the tests list to show a "Resume" badge.
  String? savedTestId() {
    final String? raw = _prefs.getString(PrefsKeys.activeRun);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['t'] as String?;
    } on Object {
      return null;
    }
  }
}
