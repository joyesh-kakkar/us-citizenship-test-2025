import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcq_item.dart';
import '../state/quiz_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_widgets.dart';
import '../widgets/favorite_button.dart';
import '../widgets/option_tile.dart';
import '../widgets/primary_button.dart';

/// Endless practice: one question, immediate feedback, then the next.
///
/// Getting one wrong is treated as information, never as failure — the
/// correct answer and the reason appear straight away.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    this.title = 'Quiz',
    this.emptyMessage =
        'There are no quiz questions in this selection yet. '
        'You can still read every question in Study.',
  });

  /// App-bar title, so the same screen can serve Quiz, Fix-your-misses, and
  /// Favorites practice (the pool is set by a `quizPoolProvider` override).
  final String title;

  /// Shown when the pool is empty — worded per entry point.
  final String emptyMessage;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _next() {
    ref.read(quizControllerProvider.notifier).next();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final QuizState state = ref.watch(quizControllerProvider);
    final ThemeData theme = Theme.of(context);
    final McqItem? item = state.item;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          if (state.answered > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.correct} of ${state.answered}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: item == null
            ? _EmptyPool(message: widget.emptyMessage)
            : ListView(
                controller: _scrollController,
                padding: kPagePadding,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(item.question.question,
                            style: theme.textTheme.headlineSmall),
                      ),
                      FavoriteButton(questionId: item.question.id),
                    ],
                  ),
                  if (item.question.expectsMultipleInRealTest) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Choose one correct answer.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 20),
                  for (int i = 0; i < item.options.length; i++) ...<Widget>[
                    OptionTile(
                      index: i,
                      label: item.options[i],
                      status: _statusFor(state, i),
                      onTap: state.hasAnswered
                          ? null
                          : () => ref.read(quizControllerProvider.notifier).answer(i),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (state.hasAnswered) ...<Widget>[
                    const SizedBox(height: 10),
                    _FeedbackBanner(correct: state.isCorrect),
                    const SizedBox(height: 16),
                    if (item.question.correctAnswers.length > 1) ...<Widget>[
                      OfficialAnswersList(
                        question: item.question,
                        heading: 'Every answer USCIS accepts',
                      ),
                      const SizedBox(height: 16),
                    ],
                    ExplanationCard(explanation: item.question.explanation),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Next question',
                      icon: Icons.arrow_forward,
                      onPressed: _next,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
      ),
    );
  }

  OptionStatus _statusFor(QuizState state, int index) {
    if (!state.hasAnswered) return OptionStatus.idle;
    final McqItem item = state.item!;
    if (item.isCorrect(index)) return OptionStatus.correct;
    if (state.selectedIndex == index) return OptionStatus.chosenWrong;
    return OptionStatus.dimmed;
  }
}

/// Shown after each answer. The wording for a wrong answer is deliberately
/// gentle: the point is the correction, not the mistake.
class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    final Color foreground = correct
        ? (isLight ? AppColors.correctFg : AppColors.correctFgDark)
        : (isLight ? AppColors.reviewFg : AppColors.reviewFgDark);
    final Color background = correct
        ? (isLight ? AppColors.correctBg : AppColors.correctBgDark)
        : (isLight ? AppColors.reviewBg : AppColors.reviewBgDark);

    final String message =
        correct ? "That's right." : "Not quite — the correct answer is marked above.";

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: correct ? AppColors.correctBorder : AppColors.reviewBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              correct ? Icons.check_circle : Icons.info_outline,
              color: foreground,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Only reachable if a future remote config left nothing quizzable in the
/// selected scope. Explains the way out rather than showing a dead end.
class _EmptyPool extends StatelessWidget {
  const _EmptyPool({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Scrollable like every other screen: at large text sizes a centred,
    // fixed-height column would clip its own message.
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 24),
        const Icon(Icons.check_circle_outline, size: 56),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
