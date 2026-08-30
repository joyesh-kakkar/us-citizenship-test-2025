import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question_bank.dart';
import '../models/scope.dart';
import '../state/providers.dart';

/// Chooses whether Quiz and Test draw from all 128 questions or only the 20
/// starred ones (the 65/20 accommodation).
///
/// Laid out as a column of full-width options rather than a segmented row:
/// at large text sizes a two-up row becomes unreadable, and the extra height
/// costs nothing on a screen this simple.
class ScopeToggle extends ConsumerWidget {
  const ScopeToggle({super.key, this.showExplainer = true});

  final bool showExplainer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StudyScope scope = ref.watch(scopeProvider);
    final QuestionBank bank = ref.watch(questionBankProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Which questions?', style: text.titleMedium),
        const SizedBox(height: 4),
        if (showExplainer)
          Text(
            'This sets what Quiz and Test ask you. Study always shows all questions.',
            style: text.bodyMedium,
          ),
        const SizedBox(height: 12),
        _ScopeOption(
          scope: StudyScope.all,
          selected: scope == StudyScope.all,
          title: 'All ${bank.questions.length}',
          subtitle: 'The standard test',
          onSelect: () => ref.read(scopeProvider.notifier).set(StudyScope.all),
        ),
        const SizedBox(height: 10),
        _ScopeOption(
          scope: StudyScope.starred,
          selected: scope == StudyScope.starred,
          title: 'Starred ${bank.starredQuestions.length}',
          subtitle: 'If you are 65 or older and have had a green card for 20 years or more',
          onSelect: () => ref.read(scopeProvider.notifier).set(StudyScope.starred),
        ),
      ],
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.scope,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onSelect,
  });

  final StudyScope scope;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // An icon as well as colour, so selection is not conveyed by
                // colour alone.
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
