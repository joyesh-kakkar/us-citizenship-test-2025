import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/remote_config.dart';
import 'question_repository.dart' show AssetLoader;

/// Where the config currently in use came from.
enum RemoteConfigSource {
  /// Shipped inside the app. Always available, works offline.
  bundled,

  /// A previously fetched copy stored on the device.
  cached,

  /// Just fetched from [kRemoteConfigUrl].
  network,
}

/// What a manual "Check for updates" actually did.
enum RefreshOutcome {
  /// A newer config was fetched and is now in use.
  updated,

  /// The fetch succeeded and matched what we already had.
  unchanged,

  /// [kRemoteConfigUrl] is still the placeholder, so there was nothing to do.
  notConfigured,

  /// Offline, timed out, or the response was unusable. Existing answers kept.
  unavailable,
}

/// The config in use plus where it came from.
@immutable
class RemoteConfigState {
  const RemoteConfigState({required this.config, required this.source, this.fetchedAt});

  final RemoteConfig config;
  final RemoteConfigSource source;

  /// When the cached/network copy was retrieved. Null for the bundled default.
  final String? fetchedAt;
}

/// Supplies the four answers that change with elections and appointments.
///
/// Resolution order is always cached → bundled, so the app is fully usable
/// offline and on first launch. A network fetch is strictly an optional
/// upgrade: every failure mode silently keeps whatever is already in use.
class RemoteConfigService {
  RemoteConfigService({
    required SharedPreferences prefs,
    http.Client? client,
    AssetLoader? assetLoader,
    String url = kRemoteConfigUrl,
    Duration timeout = kRemoteConfigTimeout,
  })  :
        // Named parameters cannot target private fields, so these are
        // assigned in the initializer list rather than as initializing formals.
        // ignore: prefer_initializing_formals
        _prefs = prefs,
        _client = client ?? http.Client(),
        _loadAsset = assetLoader ?? rootBundle.loadString,
        // ignore: prefer_initializing_formals
        _url = url,
        // ignore: prefer_initializing_formals
        _timeout = timeout;

  final SharedPreferences _prefs;
  final http.Client _client;
  final AssetLoader _loadAsset;
  final String _url;
  final Duration _timeout;

  bool get isConfigured =>
      _url.startsWith('http') && !_url.contains('REPLACE_ME');

  /// Loads without ever touching the network. Safe to await during startup.
  Future<RemoteConfigState> loadLocal() async {
    final String? cached = _prefs.getString(PrefsKeys.cachedRemoteConfig);
    if (cached != null) {
      final RemoteConfig? parsed = RemoteConfig.tryParse(cached);
      if (parsed != null) {
        return RemoteConfigState(
          config: parsed,
          source: RemoteConfigSource.cached,
          fetchedAt: _prefs.getString(PrefsKeys.cachedRemoteConfigFetchedAt),
        );
      }
      // Cached copy is corrupt; drop it and fall through to the bundled asset.
      await _prefs.remove(PrefsKeys.cachedRemoteConfig);
    }
    return _loadBundled();
  }

  /// Fetches, validates and caches a fresh config.
  ///
  /// Never throws. On any failure the caller keeps using [loadLocal]'s result.
  Future<RefreshOutcome> refresh() async {
    if (!isConfigured) return RefreshOutcome.notConfigured;

    final String body;
    try {
      final http.Response response =
          await _client.get(Uri.parse(_url)).timeout(_timeout);
      if (response.statusCode != 200) return RefreshOutcome.unavailable;
      body = response.body;
    } on Object {
      // Offline, DNS failure, timeout, TLS error, malformed URL — all the same
      // to the user: keep the answers we already have.
      return RefreshOutcome.unavailable;
    }

    if (RemoteConfig.tryParse(body) == null) return RefreshOutcome.unavailable;

    final bool changed = _prefs.getString(PrefsKeys.cachedRemoteConfig) != body;
    await _prefs.setString(PrefsKeys.cachedRemoteConfig, body);
    await _prefs.setString(
      PrefsKeys.cachedRemoteConfigFetchedAt,
      DateTime.now().toIso8601String(),
    );
    return changed ? RefreshOutcome.updated : RefreshOutcome.unchanged;
  }

  Future<RemoteConfigState> _loadBundled() async {
    try {
      final String raw = await _loadAsset(kRemoteConfigAssetPath);
      final RemoteConfig? parsed = RemoteConfig.tryParse(raw);
      if (parsed != null) {
        return RemoteConfigState(
          config: parsed,
          source: RemoteConfigSource.bundled,
        );
      }
    } on Object {
      // Fall through: an empty config only means volatile questions stay
      // study-only, which the engine already handles.
    }
    return RemoteConfigState(
      config: RemoteConfig.empty(),
      source: RemoteConfigSource.bundled,
    );
  }
}
