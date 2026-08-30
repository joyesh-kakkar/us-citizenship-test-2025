import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/progress.dart';
import '../models/scope.dart';

/// Persists study progress and the All/Starred scope locally.
///
/// Everything is stored as small primitives so a corrupt or partially written
/// value degrades to "no progress" rather than crashing the app.
class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;

  Progress load() => Progress(
        everCorrectIds: _readIds(PrefsKeys.everCorrectIds),
        missedIds: _readIds(PrefsKeys.missedIds),
        quizAnswered: _prefs.getInt(PrefsKeys.quizAnswered) ?? 0,
        quizCorrect: _prefs.getInt(PrefsKeys.quizCorrect) ?? 0,
      );

  Future<void> save(Progress progress) async {
    await _writeIds(PrefsKeys.everCorrectIds, progress.everCorrectIds);
    await _writeIds(PrefsKeys.missedIds, progress.missedIds);
    await _prefs.setInt(PrefsKeys.quizAnswered, progress.quizAnswered);
    await _prefs.setInt(PrefsKeys.quizCorrect, progress.quizCorrect);
  }

  StudyScope loadScope() => StudyScope.fromWire(_prefs.getString(PrefsKeys.scope));

  Future<void> saveScope(StudyScope scope) =>
      _prefs.setString(PrefsKeys.scope, scope.wireName);

  /// Persisted theme choice: 'system' (default), 'light', or 'dark'.
  String loadThemeMode() => _prefs.getString(PrefsKeys.themeMode) ?? 'system';

  Future<void> saveThemeMode(String mode) =>
      _prefs.setString(PrefsKeys.themeMode, mode);

  /// The set of calendar days (yyyy-mm-dd) the user has practised on, used for
  /// the encouraging "day streak".
  Set<String> loadPracticeDays() =>
      _prefs.getStringList(PrefsKeys.practiceDays)?.toSet() ?? <String>{};

  Future<void> savePracticeDays(Set<String> days) => _prefs.setStringList(
        PrefsKeys.practiceDays,
        days.toList(growable: false),
      );

  /// Clears progress only. The chosen scope and the cached remote config are
  /// settings, not progress, and survive a reset.
  Future<void> reset() async {
    for (final String key in PrefsKeys.progressKeys) {
      await _prefs.remove(key);
    }
  }

  Set<int> _readIds(String key) {
    final List<String>? raw = _prefs.getStringList(key);
    if (raw == null) return <int>{};
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _writeIds(String key, Set<int> ids) => _prefs.setStringList(
        key,
        ids.map((int id) => id.toString()).toList(growable: false),
      );
}
