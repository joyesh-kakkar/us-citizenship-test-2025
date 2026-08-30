import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Persists the set of bookmarked question ids. Local-only, never synced.
class FavoritesStore {
  FavoritesStore(this._prefs);

  final SharedPreferences _prefs;

  Set<int> load() {
    final List<String>? raw = _prefs.getStringList(PrefsKeys.favorites);
    if (raw == null) return <int>{};
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> save(Set<int> ids) => _prefs.setStringList(
        PrefsKeys.favorites,
        ids.map((int id) => id.toString()).toList(growable: false),
      );
}
