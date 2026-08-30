import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/mcq_generator.dart';
import '../models/question.dart';
import '../state/favorites_providers.dart';
import '../state/providers.dart';
import '../state/quiz_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/favorite_button.dart';
import '../widgets/primary_button.dart';
import 'quiz_screen.dart';
import 'study_questions_screen.dart';

/// The user's bookmarked questions: review them, or quiz only these.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Question> favorites = ref.watch(favoriteQuestionsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    // Only quiz favorites that are actually quizzable (not variesByState, and
    // volatile only when the config supplies an answer).
    final List<Question> quizzableFavorites =
        quizzableFrom(favorites, ref.watch(remoteConfigProvider).config);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: SafeArea(
        child: favorites.isEmpty
            ? _EmptyFavorites()
            : ListView(
                padding: kPagePadding,
                children: <Widget>[
                  if (quizzableFavorites.isNotEmpty) ...<Widget>[
                    PrimaryButton(
                      label: 'Quiz my ${quizzableFavorites.length} favorites',
                      icon: Icons.school_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const _FavoritesQuiz()),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('${favorites.length} saved', style: text.titleMedium),
                  const SizedBox(height: 12),
                  for (final Question q in favorites) ...<Widget>[
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StudyDetailScreen(questionId: q.id),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('Question ${q.id}', style: text.bodySmall),
                                const SizedBox(height: 4),
                                Text(q.question, style: text.bodyLarge),
                              ],
                            ),
                          ),
                          FavoriteButton(questionId: q.id),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: <Widget>[
        const SizedBox(height: 24),
        Icon(Icons.bookmark_border, size: 60, color: sem.accent),
        const SizedBox(height: 16),
        Text('No favorites yet', style: text.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Tap the bookmark on any question — in Study or Quiz — to save it here '
          'for quick review.',
          style: text.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Quiz restricted to the favorited, quizzable questions.
class _FavoritesQuiz extends StatelessWidget {
  const _FavoritesQuiz();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        quizPoolProvider.overrideWith((Ref ref) =>
            quizzableFrom(ref.watch(favoriteQuestionsProvider),
                ref.watch(remoteConfigProvider).config)),
      ],
      child: const QuizScreen(
        title: 'Favorites',
        emptyMessage: 'None of your favorites can be quizzed yet. '
            'They may be study-only questions.',
      ),
    );
  }
}
