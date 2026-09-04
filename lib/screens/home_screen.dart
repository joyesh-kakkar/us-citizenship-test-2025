import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice_test.dart';
import '../state/favorites_providers.dart';
import '../state/providers.dart';
import '../state/quiz_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_meter.dart';
import '../widgets/test_card.dart';
import '../widgets/tool_tile.dart';
import 'favorites_screen.dart';
import 'fix_misses_screen.dart';
import 'flashcards_screen.dart';
import 'practice_tests_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'study_categories_screen.dart';
import 'test_screen.dart';

/// The home dashboard: a warm greeting, an encouraging readiness meter, the
/// practice-test strip, and quick tiles into every study mode.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MasterySnapshot mastery = ref.watch(masteryProvider);
    final int streak = ref.watch(streakProvider);
    final int missesCount = ref.watch(missedQuestionsProvider).length;
    final int favCount = ref.watch(favoritesProvider).length;
    final List<PracticeTest> tests = ref.watch(numberedTestsProvider);
    final PracticeTest starred = ref.watch(starredTestProvider);
    final bool quizEmpty = ref.watch(scopedPoolProvider).isEmpty;
    final String? resumableId = ref.watch(resumableTestProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: <Widget>[
            _GreetingBar(streak: streak),
            const SizedBox(height: 16),
            _ReadinessCard(mastery: mastery),
            const SizedBox(height: 16),
            _SearchRow(onTap: () => _push(context, const SearchScreen())),
            const SizedBox(height: 24),

            // Practice tests strip.
            SectionHeader(
              title: 'Practice tests',
              trailing: TextButton(
                onPressed: () => _push(context, const PracticeTestsScreen()),
                child: const Text('See all'),
              ),
            ),
            // A horizontal strip whose height is driven by its content rather
            // than a fixed value, so the cards grow with the OS text size
            // instead of clipping. IntrinsicHeight + stretch makes every card
            // as tall as the tallest, keeping the row tidy.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final PracticeTest t in tests.take(6)) ...<Widget>[
                      TestCard(
                        test: t,
                        status: ref.watch(testStatusProvider(t.id)),
                        resumable: t.id == resumableId,
                        width: 190,
                        onTap: () => _push(context, TestRunnerScreen(test: t)),
                      ),
                      const SizedBox(width: 12),
                    ],
                    TestCard(
                      test: starred,
                      status: ref.watch(testStatusProvider(starred.id)),
                      resumable: starred.id == resumableId,
                      width: 190,
                      onTap: () => _push(context, TestRunnerScreen(test: starred)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scope + main practice.
            const AppCard(child: ScopeToggle()),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Start a quiz',
              icon: Icons.school_outlined,
              onPressed: quizEmpty
                  ? null
                  : () {
                      ref.invalidate(quizControllerProvider);
                      _push(context, const QuizScreen());
                    },
            ),
            const SizedBox(height: 12),
            PrimaryButton.tonal(
              label: 'Study all questions',
              icon: Icons.menu_book_outlined,
              onPressed: () => _push(context, const StudyCategoriesScreen()),
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'More ways to study'),
            // Two rows of tiles sized to their content rather than a fixed
            // aspect ratio, so they grow with the OS text size instead of
            // clipping. IntrinsicHeight keeps each pair the same height.
            _ToolRow(
              children: <Widget>[
                ToolTile(
                  icon: Icons.style_outlined,
                  label: 'Flashcards',
                  onTap: () => _push(context, const FlashcardsScreen()),
                ),
                ToolTile(
                  icon: Icons.healing_outlined,
                  label: 'Fix your misses',
                  badge: missesCount > 0 ? '$missesCount' : null,
                  onTap: () => _push(context, const FixMissesScreen()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ToolRow(
              children: <Widget>[
                ToolTile(
                  icon: Icons.bookmark_outline,
                  label: 'Favorites',
                  badge: favCount > 0 ? '$favCount' : null,
                  onTap: () => _push(context, const FavoritesScreen()),
                ),
                ToolTile(
                  icon: Icons.insights_outlined,
                  label: 'Statistics',
                  onTap: () => _push(context, const StatisticsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Questions come from the official USCIS 2025 civics test.',
                    style: text.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _push(context, const SettingsScreen()),
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  label: const Text('Settings'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

/// Looks like a search field and behaves like a button: tapping it opens the
/// real search screen with the keyboard already up. A field here would have to
/// own focus and text state that belongs on that screen.
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Search all questions',
      excludeSemantics: true,
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: AppRadii.controlR,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.controlR,
          child: Container(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(Icons.search, size: 24, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search all questions',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of two equal-width tiles whose height is driven by the taller one's
/// content, so they scale with the OS text size rather than clipping.
class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: children[0]),
          const SizedBox(width: 12),
          Expanded(child: children[1]),
        ],
      ),
    );
  }
}

class _GreetingBar extends ConsumerWidget {
  const _GreetingBar({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemantics sem = context.sem;
    final int hour = ref.watch(clockProvider)().hour;
    final String greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(greeting, style: text.bodyMedium),
              const SizedBox(height: 2),
              Text('Ready to practice?', style: text.headlineMedium),
            ],
          ),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sem.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.local_fire_department, color: sem.accent, size: 22),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: text.titleMedium?.copyWith(color: sem.accent),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Encouraging by design: it frames progress, never "you'll fail". The number
/// is how ready you are, and the copy nudges kindly toward the next step.
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.mastery});

  final MasterySnapshot mastery;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int pct = (mastery.readiness * 100).round();

    final String headline;
    final String detail;
    if (mastery.knownCount == 0) {
      headline = "Let's begin";
      detail = 'Answer a few questions and your readiness will start to grow.';
    } else if (pct < 50) {
      headline = "You're building up";
      detail = 'Keep going — every question you practice moves this up.';
    } else if (pct < 80) {
      headline = "You're on track";
      detail = 'Nicely done. A little more practice and you will be well prepared.';
    } else {
      headline = "You're nearly there";
      detail = 'Strong work. Keep your streak going and review any misses.';
    }

    return AppCard(
      child: Row(
        children: <Widget>[
          StatRing(value: mastery.readiness, label: 'ready'),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(headline, style: text.titleLarge),
                const SizedBox(height: 6),
                Text(detail, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
