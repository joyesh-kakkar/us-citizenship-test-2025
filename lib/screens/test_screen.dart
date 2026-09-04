import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mcq_item.dart';
import '../models/practice_test.dart';
import '../state/test_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/option_tile.dart';
import 'test_result_screen.dart';

/// Entry point for running a specific practice test.
///
/// Wraps the runner in a `ProviderScope` that overrides [activeTestProvider],
/// so [testControllerProvider] builds this exact test while progress, results
/// and favorites stay shared with the app-wide scope.
class TestRunnerScreen extends StatelessWidget {
  const TestRunnerScreen({super.key, required this.test});

  final PracticeTest test;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [activeTestProvider.overrideWithValue(test)],
      child: const TestScreen(),
    );
  }
}

/// A graded run that mirrors the real exam: a fixed number of questions, no
/// feedback until the end, and no timer in this MVP.
class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _next() {
    unawaited(ref.read(testControllerProvider.notifier).next());
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  /// Leaving mid-test keeps the run so it can be resumed, but discarding it is
  /// offered too — a run you no longer want should not sit there as a nag.
  Future<bool> _confirmQuit() async {
    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Leave the practice test?'),
        content: const Text(
          'Your answers are saved, so you can pick this test up where you left off.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop('stay'),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save and leave'),
          ),
        ],
      ),
    );
    if (choice == 'discard') {
      await ref.read(testControllerProvider.notifier).abandon();
    }
    return choice == 'save' || choice == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    final TestRunState state = ref.watch(testControllerProvider);
    final ThemeData theme = Theme.of(context);

    if (state.finished) return const TestResultScreen();

    final McqItem? item = state.current;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice test')),
        body: const Center(child: SizedBox.shrink()),
      );
    }

    final int questionNumber = state.index + 1;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (await _confirmQuit() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.title),
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Semantics(
                label: 'Question $questionNumber of ${state.total}',
                excludeSemantics: true,
                child: LinearProgressIndicator(
                  value: questionNumber / state.total,
                  backgroundColor: theme.colorScheme.outlineVariant,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: kPagePadding,
                  children: <Widget>[
                    Text(
                      'Question $questionNumber of ${state.total}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(item.question.question, style: theme.textTheme.headlineSmall),
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
                        // No right/wrong shown mid-test — only what you picked,
                        // and you can change it until you move on.
                        status: state.selectedIndex == i
                            ? OptionStatus.selected
                            : OptionStatus.idle,
                        onTap: () =>
                            ref.read(testControllerProvider.notifier).select(i),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'You need ${state.rule.needToPass} of ${state.rule.asked} right to pass. '
                      'Answers are shown at the end.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: state.selectedIndex == null ? null : _next,
                  icon: Icon(
                    state.isLastQuestion ? Icons.done_all : Icons.arrow_forward,
                    size: 26,
                  ),
                  label: Text(state.isLastQuestion ? 'Finish and see results' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
