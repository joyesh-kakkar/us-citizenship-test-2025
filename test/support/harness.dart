import 'dart:math';

import 'package:civics_test_app/data/remote_config_service.dart';
import 'package:civics_test_app/data/review_service.dart';
import 'package:civics_test_app/models/practice_test.dart';
import 'package:civics_test_app/models/question_bank.dart';
import 'package:civics_test_app/models/remote_config.dart';
import 'package:civics_test_app/state/providers.dart';
import 'package:civics_test_app/state/test_controller.dart';
import 'package:civics_test_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

/// A [ReviewService] that never touches the platform channel, so widget tests
/// exercising the "passed a test" flow don't reach native code.
class NoopReviewService implements ReviewService {
  const NoopReviewService();
  @override
  Future<void> requestReview() async {}
  @override
  Future<void> openStoreListing() async {}
}

/// The dependencies `main()` resolves before the first frame, resolved the
/// same way here but from disk and with a seeded [Random] so runs repeat.
class TestDeps {
  const TestDeps({required this.prefs, required this.bank, required this.config, required this.seed});

  final SharedPreferences prefs;
  final QuestionBank bank;
  final RemoteConfig config;
  final int seed;
}

QuestionBank? _bank;
RemoteConfig? _config;

/// Reads the bundled assets once, from a real async zone.
///
/// `testWidgets` bodies run inside a fake-async zone where real file I/O never
/// completes, so the assets must be loaded from `setUpAll` instead and reused
/// synchronously inside the tests.
Future<void> primeAssets() async {
  _bank ??= await loadRealBank();
  _config ??= await loadRealRemoteConfig();
}

/// The primed bank, for tests that build practice tests directly.
QuestionBank get testBank => _bank!;

/// Safe to call inside `testWidgets`: the only await is `shared_preferences`,
/// which resolves through a mocked channel rather than real I/O.
Future<TestDeps> resolveDeps({
  Map<String, Object> prefsValues = const <String, Object>{},
  RemoteConfig? config,
  int seed = 42,
}) async {
  assert(_bank != null, 'call primeAssets() from setUpAll first');
  SharedPreferences.setMockInitialValues(prefsValues);
  return TestDeps(
    prefs: await SharedPreferences.getInstance(),
    bank: _bank!,
    config: config ?? _config!,
    seed: seed,
  );
}

// `Override` is not nameable in this SDK, so the base override list is built
// inline everywhere its element type can be inferred, via this helper closure.
ProviderContainer containerFor(TestDeps deps, {DateTime? now, PracticeTest? activeTest}) =>
    ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(deps.prefs),
        questionBankProvider.overrideWithValue(deps.bank),
        initialRemoteConfigProvider.overrideWithValue(
          RemoteConfigState(config: deps.config, source: RemoteConfigSource.bundled),
        ),
        randomProvider.overrideWithValue(Random(deps.seed)),
        reviewServiceProvider.overrideWithValue(const NoopReviewService()),
        if (now != null) clockProvider.overrideWithValue(() => now),
        if (activeTest != null) activeTestProvider.overrideWithValue(activeTest),
      ],
    );

Future<ProviderContainer> testContainer({
  Map<String, Object> prefsValues = const <String, Object>{},
  RemoteConfig? config,
  int seed = 42,
  DateTime? now,
  PracticeTest? activeTest,
}) async =>
    containerFor(
      await resolveDeps(prefsValues: prefsValues, config: config, seed: seed),
      now: now,
      activeTest: activeTest,
    );

/// Wraps [child] in the app's real theme at a chosen OS text size.
///
/// A [textScale] of 2.0 stands in for a user who has turned their phone's text
/// size all the way up — the case most likely to break a layout.
Widget harnessWith(
  TestDeps deps,
  Widget child, {
  double textScale = 1.0,
  ThemeData? theme,
  DateTime? now,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(deps.prefs),
      questionBankProvider.overrideWithValue(deps.bank),
      initialRemoteConfigProvider.overrideWithValue(
        RemoteConfigState(config: deps.config, source: RemoteConfigSource.bundled),
      ),
      randomProvider.overrideWithValue(Random(deps.seed)),
      reviewServiceProvider.overrideWithValue(const NoopReviewService()),
      if (now != null) clockProvider.overrideWithValue(() => now),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.light(),
      // Override only the text scale, keeping the real viewport size that the
      // test view provides — replacing the whole MediaQueryData would leave
      // the screen zero-sized and nothing would lay out at all.
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// Scrolls until [finder] is on screen, then returns it.
///
/// Flutter builds only the visible part of a `ListView`, so anything off
/// screen has to be scrolled to before it can be found or tapped — exactly
/// what a real user would do. The target may be above or below the current
/// position, so this walks back to the top first and then down, rather than
/// only scrolling forward the way `scrollUntilVisible` does.
Future<Finder> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final Finder scrollable = find.byType(Scrollable).first;
    for (int i = 0; i < 25 && finder.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, const Offset(0, 400));
      await tester.pumpAndSettle();
    }
    for (int i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
  }
  expect(finder, findsWidgets, reason: 'could not scroll $finder into view');
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  return finder;
}

/// Scrolls [text] into view and taps it.
Future<void> scrollAndTap(WidgetTester tester, String text) async {
  await scrollTo(tester, find.text(text));
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

/// A small, low-end Android screen: the hardest target in this app's audience.
void useSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 1280);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}
