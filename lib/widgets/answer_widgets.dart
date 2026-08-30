import 'package:flutter/material.dart';

import '../config.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';

/// Every officially acceptable answer, rendered verbatim.
///
/// The app never paraphrases official answer text, and never shows only one
/// acceptable answer when USCIS accepts several.
class OfficialAnswersList extends StatelessWidget {
  const OfficialAnswersList({super.key, required this.question, this.heading});

  final Question question;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> answers = question.correctAnswers;
    if (answers.isEmpty) return const SizedBox.shrink();

    final String title = heading ??
        (answers.length == 1 ? 'Official answer' : 'Official answers (any one is correct)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: text.titleMedium),
        const SizedBox(height: 8),
        for (final String answer in answers)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.check, size: 22, color: AppColors.correctBorder),
                ),
                const SizedBox(width: 10),
                // Expanded so long answers wrap instead of overflowing when
                // the OS text size is turned up.
                Expanded(child: Text(answer, style: text.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The note shown for answers that are not fixed: the four volatile ones and
/// the four that vary by state.
class SpecialAnswerNote extends StatelessWidget {
  const SpecialAnswerNote({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    if (!question.hasChangingAnswer) return const SizedBox.shrink();

    final bool isVolatile = question.answerType == AnswerType.volatile;
    final String body = isVolatile
        ? 'This answer changes — check $kTestUpdatesUrl'
        : 'This answer depends on your state, so it is not in the quiz yet. '
            'Check the current answer for where you live.';

    return _NoteCard(
      icon: isVolatile ? Icons.update : Icons.place_outlined,
      title: isVolatile ? 'This answer can change' : 'Answers vary by state',
      body: body,
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.reviewBg : AppColors.reviewBgDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.reviewBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: isLight ? AppColors.reviewFg : AppColors.reviewFgDark, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isLight ? AppColors.reviewFg : AppColors.reviewFgDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLight ? AppColors.reviewFg : AppColors.reviewFgDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "why" behind an answer, shown after answering and in Study.
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({super.key, required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_outline, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Why', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(explanation, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
