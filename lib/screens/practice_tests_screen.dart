import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice_test.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/test_card.dart';
import 'test_screen.dart';

/// The 20 fixed numbered tests plus the 65/20 Starred track.
///
/// Each test is stable across launches and shows its status (not started /
/// best score / Passed).
class PracticeTestsScreen extends ConsumerWidget {
  const PracticeTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PracticeTest> tests = ref.watch(numberedTestsProvider);
    final PracticeTest starred = ref.watch(starredTestProvider);
    final int passed = ref.watch(testsPassedProvider);
    final String? resumableId = ref.watch(resumableTestProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice tests')),
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: <Widget>[
            Text(
              "You've passed $passed of ${tests.length} so far. Each test mirrors the real "
              'exam: ${tests.first.questionCount} questions, ${tests.first.needToPass} to pass. '
              'No timer, and you can retake any of them.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'The 65/20 track'),
            _StarredCard(test: starred),
            const SizedBox(height: 24),
            SectionHeader(title: 'All tests', subtitle: '$passed passed'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 150,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tests.length,
              itemBuilder: (BuildContext context, int index) {
                final PracticeTest test = tests[index];
                return TestCard(
                  test: test,
                  status: ref.watch(testStatusProvider(test.id)),
                  resumable: test.id == resumableId,
                  onTap: () => _openTest(context, test),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openTest(BuildContext context, PracticeTest test) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TestRunnerScreen(test: test)),
    );
  }
}

class _StarredCard extends ConsumerWidget {
  const _StarredCard({required this.test});

  final PracticeTest test;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TestStatus status = ref.watch(testStatusProvider(test.id));
    final AppSemantics sem = context.sem;
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TestRunnerScreen(test: test)),
      ),
      border: status.passed ? Border.all(color: sem.success, width: 1.5) : null,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: sem.accent.withValues(alpha: 0.12),
              borderRadius: AppRadii.controlR,
            ),
            child: Icon(Icons.star, color: sem.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(test.title, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${test.questionCount} starred questions · ${test.needToPass} to pass',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          if (status.passed)
            Icon(Icons.verified, color: sem.success, size: 26)
          else if (status.attempted)
            Text('${status.bestPercent}%', style: text.titleMedium),
        ],
      ),
    );
  }
}
