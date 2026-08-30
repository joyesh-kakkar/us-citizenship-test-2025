import 'package:civics_test_app/engine/test_generator.dart';
import 'package:civics_test_app/models/mcq_item.dart';
import 'package:civics_test_app/models/practice_test.dart';
import 'package:civics_test_app/models/remote_config.dart';
import 'package:civics_test_app/screens/favorites_screen.dart';
import 'package:civics_test_app/screens/flashcards_screen.dart';
import 'package:civics_test_app/screens/home_screen.dart';
import 'package:civics_test_app/screens/practice_tests_screen.dart';
import 'package:civics_test_app/screens/quiz_screen.dart';
import 'package:civics_test_app/screens/settings_screen.dart';
import 'package:civics_test_app/screens/statistics_screen.dart';
import 'package:civics_test_app/screens/study_categories_screen.dart';
import 'package:civics_test_app/screens/study_questions_screen.dart';
import 'package:civics_test_app/screens/test_screen.dart';
import 'package:civics_test_app/state/quiz_controller.dart';
import 'package:civics_test_app/state/test_controller.dart';
import 'package:civics_test_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// A stable numbered test, for the runner-based checks.
PracticeTest test1() => TestGenerator.generateNumbered(testBank).first;

Map<String, Widget Function()> screens() => <String, Widget Function()>{
      'Home': () => const HomeScreen(),
      'Study categories': () => const StudyCategoriesScreen(),
      'Study subcategories': () => const StudySubcategoriesScreen(category: 'American Government'),
      'Study questions': () => const StudyQuestionsScreen(
            category: 'American Government',
            subcategory: 'System of Government',
          ),
      'Study detail': () => const StudyDetailScreen(questionId: 21),
      'Quiz': () => const QuizScreen(),
      'Practice tests': () => const PracticeTestsScreen(),
      'Test runner': () => TestRunnerScreen(test: test1()),
      'Flashcards': () => const FlashcardsScreen(),
      'Favorites': () => const FavoritesScreen(),
      'Statistics': () => const StatisticsScreen(),
      'Settings': () => const SettingsScreen(),
    };

void main() {
  setUpAll(primeAssets);

  group('screens render', () {
    for (final MapEntry<String, Widget Function()> entry in screens().entries) {
      testWidgets('${entry.key} renders without error', (WidgetTester tester) async {
        useSmallPhone(tester);
        final TestDeps deps = await resolveDeps();
        await tester.pumpWidget(harnessWith(deps, entry.value()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  });

  // The acceptance criterion that matters most for this audience: a user who
  // has turned their phone's text size all the way up must still be able to
  // read and use every screen, in both light and dark. Overflow surfaces as an
  // exception during layout.
  group('layouts survive large OS text sizes', () {
    for (final bool dark in <bool>[false, true]) {
      for (final double scale in <double>[1.5, 2.0]) {
        for (final MapEntry<String, Widget Function()> entry in screens().entries) {
          final String mode = dark ? 'dark' : 'light';
          testWidgets('${entry.key} at ${scale}x ($mode)', (WidgetTester tester) async {
            useSmallPhone(tester);
            final TestDeps deps = await resolveDeps();
            await tester.pumpWidget(harnessWith(
              deps,
              entry.value(),
              textScale: scale,
              theme: dark ? AppTheme.dark() : AppTheme.light(),
            ));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull,
                reason: '${entry.key} overflowed at ${scale}x ($mode)');
          });
        }
      }
    }
  });

  group('home', () {
    testWidgets('offers the main study modes', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const HomeScreen()));
      await tester.pumpAndSettle();

      for (final String label in <String>[
        'Start a quiz',
        'Study all questions',
        'Practice tests',
        'Flashcards',
        'Fix your misses',
        'Favorites',
        'Statistics',
      ]) {
        await scrollTo(tester, find.text(label));
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('greets a first-time user without a streak', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ready to practice'), findsOneWidget);
      // No fire-streak chip when nothing has been practised.
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
    });

    testWidgets('shows a streak once there is a practice day', (WidgetTester tester) async {
      useSmallPhone(tester);
      final DateTime now = DateTime(2026, 8, 23);
      final TestDeps deps = await resolveDeps(
        prefsValues: <String, Object>{
          'progress.practiceDays': <String>['2026-08-22', '2026-08-23'],
        },
      );
      await tester.pumpWidget(harnessWith(deps, const HomeScreen(), now: now));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });
  });

  group('study', () {
    testWidgets('shows every official answer verbatim', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const StudyDetailScreen(questionId: 21)));
      await tester.pumpAndSettle();

      for (final String answer in deps.bank.byId(21)!.correctAnswers) {
        expect(find.text(answer), findsOneWidget);
      }
    });

    testWidgets('flags a variesByState question', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const StudyDetailScreen(questionId: 62)));
      await tester.pumpAndSettle();
      expect(find.text('Answers vary by state'), findsOneWidget);
    });

    testWidgets('flags a volatile question with the USCIS address',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const StudyDetailScreen(questionId: 30)));
      await tester.pumpAndSettle();
      expect(find.text('This answer can change'), findsOneWidget);
      // The USCIS address appears in the special note; the question's own
      // explanation may also mention it, so assert on the note's exact text.
      expect(
        find.text('This answer changes — check uscis.gov/citizenship/testupdates'),
        findsOneWidget,
      );
    });

    testWidgets('bookmarks a question from the detail screen',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const StudyDetailScreen(questionId: 21)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.text('Saved to Favorites'), findsOneWidget);
    });
  });

  group('quiz', () {
    testWidgets('reveals the answer and reason after a tap',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const QuizScreen()));
      await tester.pumpAndSettle();

      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(QuizScreen)));
      final McqItem item = container.read(quizControllerProvider).item!;

      await scrollAndTap(tester, item.options[item.correctIndex]);

      await scrollTo(tester, find.text("That's right."));
      expect(find.text("That's right."), findsOneWidget);
      await scrollTo(tester, find.text('Next question'));
      expect(find.text('Next question'), findsOneWidget);
    });

    testWidgets('a wrong answer is corrected, not scolded',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const QuizScreen()));
      await tester.pumpAndSettle();

      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(QuizScreen)));
      final McqItem item = container.read(quizControllerProvider).item!;
      final int wrong = (item.correctIndex + 1) % item.options.length;

      await scrollAndTap(tester, item.options[wrong]);
      await scrollTo(tester, find.textContaining('Not quite'));
      expect(find.textContaining('Not quite'), findsOneWidget);
      await scrollTo(tester, find.text('Correct answer'));
      expect(find.text('Correct answer'), findsOneWidget);
    });

    testWidgets('always offers exactly four options', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const QuizScreen()));
      await tester.pumpAndSettle();

      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(QuizScreen)));
      for (int i = 0; i < 6; i++) {
        final McqItem item = container.read(quizControllerProvider).item!;
        expect(item.options, hasLength(4));
        await scrollAndTap(tester, item.options.first);
        await scrollAndTap(tester, 'Next question');
      }
    });
  });

  group('practice test flow', () {
    testWidgets('runs a full test to a passing result', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, TestRunnerScreen(test: test1())));
      await tester.pumpAndSettle();

      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(TestScreen)));

      expect(find.text('Question 1 of 20'), findsOneWidget);
      for (int i = 0; i < 20; i++) {
        final TestRunState state = container.read(testControllerProvider);
        final McqItem item = state.current!;
        await scrollAndTap(tester, item.options[item.correctIndex]);
        await scrollAndTap(
          tester,
          state.isLastQuestion ? 'Finish and see results' : 'Next',
        );
      }

      expect(find.text('You passed!'), findsOneWidget);
      expect(find.text('20 of 20 correct'), findsOneWidget);
      await scrollTo(tester, find.text('Try this test again'));
      expect(find.text('Try this test again'), findsOneWidget);
    });

    testWidgets('a failing run lists every missed question',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, TestRunnerScreen(test: test1())));
      await tester.pumpAndSettle();

      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(TestScreen)));

      for (int i = 0; i < 20; i++) {
        final TestRunState state = container.read(testControllerProvider);
        final McqItem item = state.current!;
        final int choice =
            i < 5 ? item.correctIndex : (item.correctIndex + 1) % item.options.length;
        await scrollAndTap(tester, item.options[choice]);
        await scrollAndTap(
          tester,
          state.isLastQuestion ? 'Finish and see results' : 'Next',
        );
      }

      expect(find.text('Good effort'), findsOneWidget);
      expect(find.text('15 to look at again'), findsOneWidget);
    });

    testWidgets('will not advance until an option is chosen',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, TestRunnerScreen(test: test1())));
      await tester.pumpAndSettle();

      final Finder next = find.widgetWithText(FilledButton, 'Next');
      expect(tester.widget<FilledButton>(next).onPressed, isNull);
    });
  });

  group('favorites & fix-your-misses empty states', () {
    testWidgets('favorites invites action when empty', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const FavoritesScreen()));
      await tester.pumpAndSettle();
      expect(find.text('No favorites yet'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('reports data versions and study-only count',
        (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const SettingsScreen()));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Check for updates'));
      expect(find.text('124'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await scrollTo(tester, find.text('Rate us'));
      expect(find.text('Rate us'), findsOneWidget);
      await scrollTo(tester, find.text('Share the app'));
      expect(find.text('Share the app'), findsOneWidget);
    });

    testWidgets('offers a dark-mode toggle', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps();
      await tester.pumpWidget(harnessWith(deps, const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('confirms before clearing progress', (WidgetTester tester) async {
      useSmallPhone(tester);
      final TestDeps deps = await resolveDeps(
        prefsValues: <String, Object>{'progress.everCorrectIds': <String>['1', '2']},
      );
      await tester.pumpWidget(harnessWith(deps, const SettingsScreen()));
      await tester.pumpAndSettle();

      await scrollAndTap(tester, 'Start over');
      expect(find.text('Start over?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Start over?'), findsNothing);
    });
  });

  // Silence the unused-import lint for RemoteConfig, kept for future use.
  test('remote config type is importable', () {
    expect(RemoteConfig.empty().answers, isEmpty);
  });
}
