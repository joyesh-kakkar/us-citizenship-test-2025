import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/progress.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_meter.dart';
import 'topic_quiz_screen.dart';

/// An encouraging, no-pressure dashboard: how much of the bank is known, mastery
/// per category, tests passed, and the practice streak. No dark patterns.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MasterySnapshot mastery = ref.watch(masteryProvider);
    final int streak = ref.watch(streakProvider);
    final int testsPassed = ref.watch(testsPassedProvider);
    final int totalTests = ref.watch(numberedTestsProvider).length;
    final Progress progress = ref.watch(progressProvider);
    final String? weakest = ref.watch(weakestCategoryProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: <Widget>[
            AppCard(
              child: Row(
                children: <Widget>[
                  StatRing(value: mastery.readiness, label: 'ready'),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Overall', style: text.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          '${mastery.knownCount} of ${mastery.totalCount} questions '
                          'answered correctly at least once.',
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _MiniStat(
                    icon: Icons.local_fire_department,
                    value: '$streak',
                    label: streak == 1 ? 'day streak' : 'days streak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.verified,
                    value: '$testsPassed/$totalTests',
                    label: 'tests passed',
                  ),
                ),
              ],
            ),
            if (progress.quizAnswered > 0) ...<Widget>[
              const SizedBox(height: 16),
              _AccuracyCard(
                answered: progress.quizAnswered,
                correct: progress.quizCorrect,
              ),
            ],
            if (weakest != null) ...<Widget>[
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Practice $weakest',
                icon: Icons.trending_up,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TopicQuizScreen(category: weakest),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'By topic',
              subtitle: 'Tap a topic to practice just those questions',
            ),
            for (final MapEntry<String, (int, int)> entry
                in mastery.perCategory.entries) ...<Widget>[
              _CategoryBar(
                name: entry.key,
                known: entry.value.$1,
                total: entry.value.$2,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TopicQuizScreen(category: entry.key),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 8),
            Text(
              'Everything here stays on your phone. This is just to encourage you — '
              'the only thing that counts is the real interview.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Lifetime answering accuracy. Framed as practice done rather than a grade:
/// the number climbs as you use the app, and it is never described as a score
/// you could fail.
class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({required this.answered, required this.correct});

  final int answered;
  final int correct;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int percent = answered == 0 ? 0 : ((correct / answered) * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Answers so far', style: text.titleMedium)),
              Text('$percent%', style: text.titleLarge),
            ],
          ),
          const SizedBox(height: 10),
          StatMeter(value: answered == 0 ? 0 : correct / answered,
              color: context.sem.accent),
          const SizedBox(height: 10),
          Text(
            answered == 1
                ? "You've answered 1 question, and got it "
                    '${correct == 1 ? 'right' : 'wrong'}.'
                : "You've answered $answered questions and got $correct right. "
                    'This counts every quiz and practice test.',
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: sem.accent, size: 28),
          const SizedBox(height: 10),
          Text(value, style: text.headlineSmall),
          Text(label, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.name,
    required this.known,
    required this.total,
    required this.onTap,
  });

  final String name;
  final int known;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final double fraction = total == 0 ? 0 : known / total;

    return Semantics(
      button: true,
      label: 'Practice $name. $known of $total answered correctly.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(name, style: text.titleSmall)),
                    Text('$known / $total', style: text.bodyMedium),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 22, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 8),
                StatMeter(value: fraction, color: context.sem.success),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
