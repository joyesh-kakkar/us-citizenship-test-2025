import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../state/quiz_controller.dart';
import 'quiz_screen.dart';

/// Practice restricted to one official category.
///
/// Statistics knows which topic the user is weakest on; this is how they act
/// on it without hunting through Study for the right questions.
class TopicQuizScreen extends StatelessWidget {
  const TopicQuizScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        quizPoolProvider.overrideWith((Ref ref) => ref.watch(categoryPoolProvider(category))),
      ],
      child: QuizScreen(
        title: category,
        emptyMessage: 'There are no quiz questions in this topic yet. '
            'You can still read every question in Study.',
      ),
    );
  }
}
