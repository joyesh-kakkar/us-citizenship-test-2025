import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/practice_test.dart';

/// Per-test best score / passed status, plus the one-shot "have we already
/// asked for a store review" flag.
class TestResultsStore {
  TestResultsStore(this._prefs);

  final SharedPreferences _prefs;

  Map<String, TestStatus> load() {
    final String? raw = _prefs.getString(PrefsKeys.testResults);
    if (raw == null) return <String, TestStatus>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, TestStatus>{};
      return decoded.map((String key, Object? value) => MapEntry<String, TestStatus>(
            key,
            TestStatus.fromJson(value as Map<String, dynamic>),
          ));
    } on Object {
      // A corrupt blob degrades to "no results", never a crash.
      return <String, TestStatus>{};
    }
  }

  Future<void> save(Map<String, TestStatus> results) {
    final Map<String, dynamic> json = results.map(
      (String key, TestStatus value) => MapEntry<String, dynamic>(key, value.toJson()),
    );
    return _prefs.setString(PrefsKeys.testResults, jsonEncode(json));
  }

  bool get reviewPrompted => _prefs.getBool(PrefsKeys.reviewPrompted) ?? false;

  Future<void> markReviewPrompted() => _prefs.setBool(PrefsKeys.reviewPrompted, true);
}
