import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../state/quiz_controller.dart';
import 'quiz_screen.dart';

/// "Fix your misses": quizzes only the questions the user has gotten wrong.
///
/// It overrides [quizPoolProvider] with the live misses pool. Answering one
/// correctly removes it from misses (via progress), so the pool shrinks as the
/// user recovers each question — and the screen shows an encouraging empty
/// state once there is nothing left to review.
class FixMissesScreen extends StatelessWidget {
  const FixMissesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        quizPoolProvider.overrideWith((Ref ref) => ref.watch(missedQuestionsProvider)),
      ],
      child: const QuizScreen(
        title: 'Fix your misses',
        emptyMessage:
            "No misses to review — nice work! Anything you get wrong in Quiz or a "
            'test will show up here.',
      ),
    );
  }
}
