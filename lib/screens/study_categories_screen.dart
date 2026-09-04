import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question_bank.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';
import 'study_questions_screen.dart';

/// Study, level 1: the three official categories.
class StudyCategoriesScreen extends ConsumerWidget {
  const StudyCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionBank bank = ref.watch(questionBankProvider);
    final List<String> categories = bank.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search questions',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: kPagePadding,
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Read the questions and the official answers. Nothing here is timed or scored.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }
            final String category = categories[index - 1];
            return _NavCard(
              title: category,
              subtitle: '${bank.countIn(category)} questions',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudySubcategoriesScreen(category: category),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Study, level 2: subcategories inside one category.
class StudySubcategoriesScreen extends ConsumerWidget {
  const StudySubcategoriesScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionBank bank = ref.watch(questionBankProvider);
    final List<String> subcategories = bank.subcategoriesOf(category);

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: SafeArea(
        child: ListView.separated(
          padding: kPagePadding,
          itemCount: subcategories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final String subcategory = subcategories[index];
            return _NavCard(
              title: subcategory,
              subtitle: '${bank.questionsIn(category, subcategory).length} questions',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudyQuestionsScreen(
                    category: category,
                    subcategory: subcategory,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A large, obvious row that leads somewhere.
class _NavCard extends StatelessWidget {
  const _NavCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, size: 30, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
