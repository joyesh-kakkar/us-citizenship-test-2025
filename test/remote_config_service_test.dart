import 'dart:convert';

import 'package:civics_test_app/config.dart';
import 'package:civics_test_app/data/remote_config_service.dart';
import 'package:civics_test_app/models/remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixtures.dart';

const String _url = 'https://example.test/remote_config.json';

String configJson({
  String version = 'v2',
  List<String> correct = const <String>['Mike Johnson'],
  List<String> distractors = const <String>['A', 'B', 'C'],
}) =>
    jsonEncode(<String, Object?>{
      'version': version,
      'updatedAt': '2026-01-01',
      'answers': <String, Object?>{
        'speaker': <String, Object?>{'correct': correct, 'distractors': distractors},
      },
    });

/// Stands in for the bundled asset so the fallback chain can be tested without
/// a Flutter asset binding.
Future<String> Function(String) assetReturning(String body) =>
    (String path) async => body;

Future<String> failingAsset(String path) async =>
    throw StateError('asset unavailable');

RemoteConfigService service({
  required SharedPreferences prefs,
  http.Client? client,
  Future<String> Function(String)? asset,
  String url = _url,
  Duration timeout = const Duration(seconds: 5),
}) =>
    RemoteConfigService(
      prefs: prefs,
      client: client ?? MockClient((http.Request _) async => http.Response('', 500)),
      assetLoader: asset ?? assetReturning(configJson(version: 'bundled')),
      url: url,
      timeout: timeout,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  group('loadLocal', () {
    test('uses the bundled asset on a first launch with no cache', () async {
      final RemoteConfigState state = await service(prefs: await prefs()).loadLocal();

      expect(state.source, RemoteConfigSource.bundled);
      expect(state.config.version, 'bundled');
      expect(state.config.answers['speaker']!.isUsable, isTrue);
    });

    test('prefers a valid cached copy over the bundled asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsKeys.cachedRemoteConfig: configJson(version: 'cached'),
        PrefsKeys.cachedRemoteConfigFetchedAt: '2026-02-02T00:00:00.000',
      });

      final RemoteConfigState state = await service(prefs: await prefs()).loadLocal();

      expect(state.source, RemoteConfigSource.cached);
      expect(state.config.version, 'cached');
      expect(state.fetchedAt, '2026-02-02T00:00:00.000');
    });

    test('discards a corrupt cache and falls back to the bundled asset', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsKeys.cachedRemoteConfig: 'not json at all',
      });
      final SharedPreferences store = await prefs();

      final RemoteConfigState state = await service(prefs: store).loadLocal();

      expect(state.source, RemoteConfigSource.bundled);
      expect(store.getString(PrefsKeys.cachedRemoteConfig), isNull,
          reason: 'the unusable cache should be cleared');
    });

    test('degrades to an empty config when even the asset is unreadable', () async {
      final RemoteConfigState state =
          await service(prefs: await prefs(), asset: failingAsset).loadLocal();

      // Not a crash: volatile questions simply stay study-only.
      expect(state.config.answers, isEmpty);
      expect(state.config.usableAnswerCount, 0);
    });

    test('never performs a network request', () async {
      bool called = false;
      final MockClient client = MockClient((http.Request _) async {
        called = true;
        return http.Response(configJson(), 200);
      });

      await service(prefs: await prefs(), client: client).loadLocal();

      expect(called, isFalse);
    });
  });

  group('refresh', () {
    test('caches a valid response and reports it as updated', () async {
      final SharedPreferences store = await prefs();
      final MockClient client =
          MockClient((http.Request _) async => http.Response(configJson(version: 'v9'), 200));

      final RefreshOutcome outcome =
          await service(prefs: store, client: client).refresh();

      expect(outcome, RefreshOutcome.updated);
      expect(store.getString(PrefsKeys.cachedRemoteConfig), contains('v9'));
      expect(store.getString(PrefsKeys.cachedRemoteConfigFetchedAt), isNotNull);

      final RemoteConfigState state =
          await service(prefs: store, client: client).loadLocal();
      expect(state.config.version, 'v9');
      expect(state.source, RemoteConfigSource.cached);
    });

    test('reports unchanged when the response matches the cache', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefsKeys.cachedRemoteConfig: configJson(version: 'same'),
      });
      final MockClient client =
          MockClient((http.Request _) async => http.Response(configJson(version: 'same'), 200));

      expect(
        await service(prefs: await prefs(), client: client).refresh(),
        RefreshOutcome.unchanged,
      );
    });

    test('does nothing while the URL is still the placeholder', () async {
      bool called = false;
      final MockClient client = MockClient((http.Request _) async {
        called = true;
        return http.Response(configJson(), 200);
      });

      final RefreshOutcome outcome = await service(
        prefs: await prefs(),
        client: client,
        url: 'REPLACE_ME',
      ).refresh();

      expect(outcome, RefreshOutcome.notConfigured);
      expect(called, isFalse);
    });

    // Each of these must leave the existing answers untouched rather than
    // surfacing an error: the refresh is an optional upgrade, never a
    // precondition for using the app.
    final Map<String, http.Client> failures = <String, http.Client>{
      'offline': MockClient((http.Request _) async => throw const SocketExceptionStub()),
      'non-200': MockClient((http.Request _) async => http.Response('nope', 404)),
      'malformed JSON': MockClient((http.Request _) async => http.Response('{oh no', 200)),
      'JSON that is not an object':
          MockClient((http.Request _) async => http.Response('[1, 2, 3]', 200)),
      'object with no answers map':
          MockClient((http.Request _) async => http.Response('{"version":"x"}', 200)),
    };

    failures.forEach((String name, http.Client client) {
      test('keeps the cached copy when the fetch fails: $name', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          PrefsKeys.cachedRemoteConfig: configJson(version: 'kept'),
        });
        final SharedPreferences store = await prefs();

        final RefreshOutcome outcome =
            await service(prefs: store, client: client).refresh();

        expect(outcome, RefreshOutcome.unavailable);
        expect(store.getString(PrefsKeys.cachedRemoteConfig), contains('kept'));

        final RemoteConfigState state = await service(prefs: store).loadLocal();
        expect(state.config.version, 'kept');
      });
    });

    test('falls back to the bundled asset when a fetch fails with no cache', () async {
      final MockClient client =
          MockClient((http.Request _) async => throw const SocketExceptionStub());
      final SharedPreferences store = await prefs();

      expect(
        await service(prefs: store, client: client).refresh(),
        RefreshOutcome.unavailable,
      );
      final RemoteConfigState state = await service(prefs: store).loadLocal();
      expect(state.source, RemoteConfigSource.bundled);
      expect(state.config.version, 'bundled');
    });

    test('treats a timeout as unavailable', () async {
      final MockClient client = MockClient((http.Request _) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(configJson(), 200);
      });

      final RefreshOutcome outcome = await service(
        prefs: await prefs(),
        client: client,
        timeout: const Duration(milliseconds: 20),
      ).refresh();

      expect(outcome, RefreshOutcome.unavailable);
    });
  });

  group('config parsing', () {
    test('drops a malformed entry without failing the whole document', () async {
      final String raw = jsonEncode(<String, Object?>{
        'version': 'mixed',
        'answers': <String, Object?>{
          'president': <String, Object?>{
            'correct': <String>['Someone'],
            'distractors': <String>['A', 'B', 'C'],
          },
          'speaker': 'this should be an object',
          'chiefJustice': <String, Object?>{'correct': <int>[1, 2], 'distractors': <String>[]},
        },
      });

      final RemoteConfig config = RemoteConfig.tryParse(raw)!;

      expect(config.answers.containsKey('president'), isTrue);
      expect(config.answers.containsKey('speaker'), isFalse);
      expect(config.answers.containsKey('chiefJustice'), isFalse);
      expect(config.usableAnswerCount, 1);
    });

    test('accepts the placeholder shape with empty arrays', () async {
      final String raw = jsonEncode(<String, Object?>{
        'version': 'REPLACE_ME',
        'updatedAt': 'REPLACE_ME',
        'answers': <String, Object?>{
          'president': <String, Object?>{'correct': <String>[], 'distractors': <String>[]},
        },
      });

      final RemoteConfig config = RemoteConfig.tryParse(raw)!;

      expect(config.answers['president'], isNotNull);
      expect(config.answers['president']!.isUsable, isFalse,
          reason: 'empty arrays are valid but leave the question study-only');
    });

    test('the bundled asset that ships with the app is valid and usable', () async {
      final RemoteConfig config = await loadRealRemoteConfig();

      expect(config.answers.keys,
          containsAll(<String>['president', 'vicePresident', 'speaker', 'chiefJustice']));
      expect(config.usableAnswerCount, 4,
          reason: 'the shipped config should make all four volatile questions quizzable');
    });
  });
}

/// A stand-in for a network error, so the test does not depend on dart:io.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
