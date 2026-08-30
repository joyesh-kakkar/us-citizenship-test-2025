import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/progress.dart';
import '../models/question.dart';
import '../models/question_bank.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_widgets.dart';
import '../widgets/favorite_button.dart';

/// Study, level 3: every question in one subcategory.
class StudyQuestionsScreen extends ConsumerWidget {
  const StudyQuestionsScreen({
    super.key,
    required this.category,
    required this.subcategory,
  });

  final String category;
  final String subcategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionBank bank = ref.watch(questionBankProvider);
    final Progress progress = ref.watch(progressProvider);
    final List<Question> questions = bank.questionsIn(category, subcategory);

    return Scaffold(
      appBar: AppBar(title: Text(subcategory)),
      body: SafeArea(
        child: ListView.separated(
          padding: kPagePadding,
          itemCount: questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int index) {
            final Question question = questions[index];
            return _QuestionRow(
              question: question,
              answeredCorrectly: progress.everCorrectIds.contains(question.id),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudyDetailScreen(questionId: question.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.answeredCorrectly,
    required this.onTap,
  });

  final Question question;
  final bool answeredCorrectly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTapTarget + 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Question ${question.id}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(question.question, style: theme.textTheme.bodyLarge),
                    if (question.starred || answeredCorrectly) ...<Widget>[
                      const SizedBox(height: 8),
                      // Wrap, not Row: badges stack instead of overflowing
                      // when the text size is large.
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: <Widget>[
                          if (question.starred)
                            _Badge(
                              icon: Icons.star,
                              label: 'Starred',
                              color: theme.colorScheme.primary,
                            ),
                          if (answeredCorrectly)
                            const _Badge(
                              icon: Icons.check_circle,
                              label: 'Answered correctly',
                              color: AppColors.correctBorder,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 28, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Study, level 4: one question with every official answer and the "why".
class StudyDetailScreen extends ConsumerWidget {
  const StudyDetailScreen({super.key, required this.questionId});

  final int questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionBank bank = ref.watch(questionBankProvider);
    final Question? question = bank.byId(questionId);
    final ThemeData theme = Theme.of(context);

    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question')),
        body: const Center(child: Text('That question could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${question.id}'),
        actions: <Widget>[FavoriteButton(questionId: question.id)],
      ),
      body: SafeArea(
        child: ListView(
          padding: kPagePadding,
          children: <Widget>[
            if (question.starred) ...<Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.star, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'One of the 20 starred questions',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Text(question.question, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            if (question.hasChangingAnswer) ...<Widget>[
              SpecialAnswerNote(question: question),
              const SizedBox(height: 20),
            ],
            OfficialAnswersList(question: question),
            if (question.correctAnswers.isNotEmpty) const SizedBox(height: 20),
            ExplanationCard(explanation: question.explanation),
            const SizedBox(height: 16),
            Text(
              '${question.category} · ${question.subcategory}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
