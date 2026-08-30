import 'package:civics_test_app/config.dart';
import 'package:civics_test_app/data/progress_store.dart';
import 'package:civics_test_app/models/progress.dart';
import 'package:civics_test_app/models/scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProgressStore> store([Map<String, Object> initial = const <String, Object>{}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return ProgressStore(await SharedPreferences.getInstance());
  }

  test('starts empty on a first launch', () async {
    final Progress progress = (await store()).load();

    expect(progress.everCorrectIds, isEmpty);
    expect(progress.missedIds, isEmpty);
    expect(progress.quizAnswered, 0);
    expect(progress.quizCorrect, 0);
  });

  test('round-trips progress through storage', () async {
    final ProgressStore s = await store();
    final Progress saved = Progress.empty()
        .recordAnswer(questionId: 1, correct: true)
        .recordAnswer(questionId: 2, correct: false);

    await s.save(saved);

    expect(s.load(), saved);
  });

  test('a correct answer clears the question from the review list', () async {
    Progress progress = Progress.empty().recordAnswer(questionId: 5, correct: false);
    expect(progress.missedIds, <int>{5});

    progress = progress.recordAnswer(questionId: 5, correct: true);

    expect(progress.missedIds, isEmpty);
    expect(progress.everCorrectIds, <int>{5});
    expect(progress.quizAnswered, 2);
    expect(progress.quizCorrect, 1);
  });

  test('a later wrong answer does not erase that it was once known', () async {
    final Progress progress = Progress.empty()
        .recordAnswer(questionId: 9, correct: true)
        .recordAnswer(questionId: 9, correct: false);

    expect(progress.everCorrectIds, <int>{9});
    expect(progress.missedIds, <int>{9});
  });

  test('reset clears progress but keeps the scope and cached config', () async {
    final ProgressStore s = await store(<String, Object>{
      PrefsKeys.cachedRemoteConfig: '{"answers":{}}',
    });
    await s.saveScope(StudyScope.starred);
    await s.save(Progress.empty().recordAnswer(questionId: 3, correct: true));

    await s.reset();

    expect(s.load(), Progress.empty());
    expect(s.loadScope(), StudyScope.starred);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PrefsKeys.cachedRemoteConfig), isNotNull);
  });

  test('defaults to the all-questions scope', () async {
    expect((await store()).loadScope(), StudyScope.all);
  });

  test('round-trips the scope', () async {
    final ProgressStore s = await store();
    await s.saveScope(StudyScope.starred);
    expect(s.loadScope(), StudyScope.starred);
  });

  test('ignores corrupt id values rather than crashing', () async {
    final ProgressStore s = await store(<String, Object>{
      PrefsKeys.everCorrectIds: <String>['1', 'not-a-number', '3'],
    });

    expect(s.load().everCorrectIds, <int>{1, 3});
  });
}
