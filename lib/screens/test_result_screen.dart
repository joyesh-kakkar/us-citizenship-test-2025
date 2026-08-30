import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcq_item.dart';
import '../state/providers.dart';
import '../state/test_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_widgets.dart';
import '../widgets/favorite_button.dart';
import '../widgets/primary_button.dart';
import 'study_questions_screen.dart';

/// The end of a practice test.
///
/// Passing is celebrated; not passing is framed as a list of things to look
/// at next, because the user is preparing for something that matters and
/// discouragement here has a real cost.
class TestResultScreen extends ConsumerStatefulWidget {
  const TestResultScreen({super.key});

  @override
  ConsumerState<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends ConsumerState<TestResultScreen> {
  @override
  void initState() {
    super.initState();
    // The first pass of any test is peak goodwill — ask for a store review,
    // but only once, ever.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRequestReview());
  }

  Future<void> _maybeRequestReview() async {
    if (!ref.read(testControllerProvider).justPassedFirstTime) return;
    final results = ref.read(testResultsProvider.notifier);
    if (results.reviewAlreadyPrompted) return;
    await results.markReviewPrompted();
    await ref.read(reviewServiceProvider).requestReview();
  }

  @override
  Widget build(BuildContext context) {
    final TestRunState state = ref.watch(testControllerProvider);
    final ThemeData theme = Theme.of(context);
    final bool passed = state.passed;
    final List<McqItem> missed = state.missedItems;

    return PopScope<Object?>(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your results'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: kPagePadding,
            children: <Widget>[
              _ScoreCard(
                title: state.title,
                passed: passed,
                correct: state.correctCount,
                total: state.total,
                needToPass: state.rule.needToPass,
              ),
              const SizedBox(height: 24),
              if (missed.isEmpty)
                Text(
                  'You answered every question correctly.',
                  style: theme.textTheme.bodyLarge,
                )
              else ...<Widget>[
                Text(
                  missed.length == 1
                      ? 'One to look at again'
                      : '${missed.length} to look at again',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Here is the right answer for each one, and why.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                for (final McqItem item in missed) ...<Widget>[
                  _MissedQuestionCard(item: item),
                  const SizedBox(height: 14),
                ],
              ],
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Try this test again',
                icon: Icons.refresh,
                onPressed: () => ref.read(testControllerProvider.notifier).start(),
              ),
              const SizedBox(height: 12),
              PrimaryButton.tonal(
                label: 'Back to tests',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.title,
    required this.passed,
    required this.correct,
    required this.total,
    required this.needToPass,
  });

  final String title;
  final bool passed;
  final int correct;
  final int total;
  final int needToPass;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    final Color foreground = passed
        ? (isLight ? AppColors.correctFg : AppColors.correctFgDark)
        : (isLight ? AppColors.reviewFg : AppColors.reviewFgDark);
    final Color background = passed
        ? (isLight ? AppColors.correctBg : AppColors.correctBgDark)
        : (isLight ? AppColors.reviewBg : AppColors.reviewBgDark);

    final String headline = passed ? 'You passed!' : 'Good effort';
    final String detail = passed
        ? 'You got $correct out of $total right. On the real test you need $needToPass.'
        : 'You got $correct out of $total right. You need $needToPass to pass — '
            'that gap closes quickly with a little more practice.';

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: passed ? AppColors.correctBorder : AppColors.reviewBorder,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  passed ? Icons.celebration : Icons.trending_up,
                  size: 40,
                  color: foreground,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    headline,
                    style: theme.textTheme.headlineMedium?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: foreground)),
            const SizedBox(height: 6),
            Text(
              '$correct of $total correct',
              style: theme.textTheme.headlineSmall?.copyWith(color: foreground),
            ),
            const SizedBox(height: 8),
            Text(detail, style: theme.textTheme.bodyLarge?.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

class _MissedQuestionCard extends StatelessWidget {
  const _MissedQuestionCard({required this.item});

  final McqItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(item.question.question, style: theme.textTheme.titleMedium),
              ),
              FavoriteButton(questionId: item.question.id),
            ],
          ),
          const SizedBox(height: 8),
          OfficialAnswersList(
            question: item.question,
            heading: item.question.correctAnswers.length > 1
                ? 'Official answers (any one is correct)'
                : 'Official answer',
          ),
          const SizedBox(height: 14),
          Text(item.question.explanation, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudyDetailScreen(questionId: item.question.id),
                ),
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 22),
              label: const Text('Study this question'),
            ),
          ),
        ],
      ),
    );
  }
}
