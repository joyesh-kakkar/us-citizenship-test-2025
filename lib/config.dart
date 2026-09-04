/// App-wide constants that a developer may need to change.
library;

/// URL of the hosted remote-config JSON that supplies the four "volatile"
/// answers (President, Vice President, Speaker of the House, Chief Justice).
///
/// ---------------------------------------------------------------------------
/// REPLACE_ME — set this to the HTTPS URL where you host a copy of
/// `assets/data/remote_config.json`, for example:
///
///     const String kRemoteConfigUrl =
///         'https://example.com/civics/remote_config.json';
///
/// While it is left as the placeholder below, the app never touches the
/// network: it simply uses the bundled asset. Everything still works offline.
/// ---------------------------------------------------------------------------
const String kRemoteConfigUrl = 'REPLACE_ME';

/// Whether a real URL has been filled in above.
bool get isRemoteConfigUrlConfigured =>
    kRemoteConfigUrl.startsWith('http') && !kRemoteConfigUrl.contains('REPLACE_ME');

/// Kept short: the fetch is optional and must never make the app feel slow.
const Duration kRemoteConfigTimeout = Duration(seconds: 5);

const String kQuestionsAssetPath = 'assets/data/civics_questions.json';
const String kRemoteConfigAssetPath = 'assets/data/remote_config.json';

/// Shown verbatim next to answers that change with elections/appointments.
const String kTestUpdatesUrl = 'uscis.gov/citizenship/testupdates';

/// Number of options in every generated multiple-choice item.
const int kOptionCount = 4;

/// How many numbered practice tests to generate, and their shape. Thresholds
/// themselves come from `meta`; these are the catalogue dimensions.
const int kPracticeTestCount = 20;

/// Seed for the deterministic practice-test generator. Changing it reshuffles
/// every test, so it is a constant, not a runtime value.
const int kPracticeTestSeed = 2025;

/// `shared_preferences` keys. Grouped so [PrefsKeys.progressKeys] can be
/// cleared by "reset progress" without discarding the cached remote config.
abstract final class PrefsKeys {
  static const String everCorrectIds = 'progress.everCorrectIds';
  static const String missedIds = 'progress.missedIds';
  static const String quizAnswered = 'progress.quizAnswered';
  static const String quizCorrect = 'progress.quizCorrect';
  static const String practiceDays = 'progress.practiceDays';
  static const String scope = 'settings.scope';

  static const String favorites = 'favorites.ids';
  static const String testResults = 'tests.results';
  static const String reviewPrompted = 'review.prompted';
  static const String themeMode = 'settings.themeMode';

  static const String cachedRemoteConfig = 'remoteConfig.json';
  static const String cachedRemoteConfigFetchedAt = 'remoteConfig.fetchedAt';

  /// A practice test the user left part-way through, so it can be resumed.
  static const String activeRun = 'tests.activeRun';

  /// Cleared by "reset progress". Deliberately excludes the cached config, the
  /// chosen scope, theme, and favorites, which are settings rather than
  /// progress.
  ///
  /// [reviewPrompted] is also excluded: "asked for a review once, ever" is a
  /// promise to the user, not progress, and starting over must not re-arm the
  /// prompt.
  static const List<String> progressKeys = <String>[
    everCorrectIds,
    missedIds,
    quizAnswered,
    quizCorrect,
    practiceDays,
    testResults,
    activeRun,
  ];
}
