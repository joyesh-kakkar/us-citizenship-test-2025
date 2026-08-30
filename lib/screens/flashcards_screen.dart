import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../models/question_bank.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_widgets.dart';
import '../widgets/app_card.dart';
import '../widgets/favorite_button.dart';
import '../widgets/primary_button.dart';

/// Browse questions as cards: read the question, tap to flip for the official
/// answers and the "why". Filterable by category and by All-128 / Starred.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  String? _category; // null = all categories
  bool _starredOnly = false;
  int _index = 0;
  bool _flipped = false;

  List<Question> _deck(QuestionBank bank) {
    Iterable<Question> qs = bank.questions;
    if (_starredOnly) qs = qs.where((Question q) => q.starred);
    if (_category != null) qs = qs.where((Question q) => q.category == _category);
    return qs.toList(growable: false);
  }

  void _go(int delta, int length) {
    setState(() {
      _index = (_index + delta) % length;
      if (_index < 0) _index += length;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final QuestionBank bank = ref.watch(questionBankProvider);
    final List<Question> deck = _deck(bank);
    final TextTheme text = Theme.of(context).textTheme;

    if (_index >= deck.length) _index = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _Filters(
                category: _category,
                categories: bank.categories,
                starredOnly: _starredOnly,
                onCategory: (String? c) => setState(() {
                  _category = c;
                  _index = 0;
                  _flipped = false;
                }),
                onStarred: (bool v) => setState(() {
                  _starredOnly = v;
                  _index = 0;
                  _flipped = false;
                }),
              ),
            ),
            Expanded(
              child: deck.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No cards match this filter.',
                          style: text.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _Card(question: deck[_index], flipped: _flipped, onFlip: () {
                      setState(() => _flipped = !_flipped);
                    }),
            ),
            if (deck.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                // Counter above the buttons rather than between them, so the
                // Back/Next controls keep their full width even when the OS
                // text size is large.
                child: Column(
                  children: <Widget>[
                    Text('${_index + 1} / ${deck.length}', style: text.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: PrimaryButton.tonal(
                            label: 'Back',
                            icon: Icons.chevron_left,
                            onPressed: () => _go(-1, deck.length),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Next',
                            icon: Icons.chevron_right,
                            onPressed: () => _go(1, deck.length),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.category,
    required this.categories,
    required this.starredOnly,
    required this.onCategory,
    required this.onStarred,
  });

  final String? category;
  final List<String> categories;
  final bool starredOnly;
  final ValueChanged<String?> onCategory;
  final ValueChanged<bool> onStarred;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterChip(
            label: const Text('Starred only'),
            selected: starredOnly,
            onSelected: onStarred,
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('All topics'),
            selected: category == null,
            onSelected: (_) => onCategory(null),
          ),
          for (final String c in categories) ...<Widget>[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(c),
              selected: category == c,
              onSelected: (_) => onCategory(c),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.question, required this.flipped, required this.onFlip});

  final Question question;
  final bool flipped;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AppCard(
        onTap: onFlip,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Text('Question ${question.id}', style: text.bodySmall)),
                  FavoriteButton(questionId: question.id),
                ],
              ),
              const SizedBox(height: 8),
              Text(question.question, style: text.headlineSmall),
              const SizedBox(height: 20),
              if (!flipped)
                Row(
                  children: <Widget>[
                    Icon(Icons.touch_app_outlined, size: 20, color: context.sem.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Tap to see the answer', style: text.bodyMedium)),
                  ],
                )
              else ...<Widget>[
                const Divider(height: 28),
                if (question.hasChangingAnswer) ...<Widget>[
                  SpecialAnswerNote(question: question),
                  const SizedBox(height: 16),
                ],
                OfficialAnswersList(question: question),
                if (question.correctAnswers.isNotEmpty) const SizedBox(height: 16),
                Text(question.explanation, style: text.bodyLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
