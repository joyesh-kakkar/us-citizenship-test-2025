import 'package:flutter/material.dart';

import '../models/practice_test.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// A practice-test card for the Home strip and the tests list: number, status,
/// best score, and a Passed badge once cleared.
class TestCard extends StatelessWidget {
  const TestCard({
    super.key,
    required this.test,
    required this.status,
    required this.onTap,
    this.width,
  });

  final PracticeTest test;
  final TestStatus status;
  final VoidCallback onTap;

  /// Fixed width for the horizontal Home strip; null lets it fill its parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final TextTheme text = Theme.of(context).textTheme;
    final bool passed = status.passed;

    final Widget card = AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      border: passed ? Border.all(color: sem.success, width: 1.5) : null,
      semanticLabel: <String>[
        test.title,
        '${test.questionCount} questions',
        if (passed) 'passed' else if (status.attempted) 'best ${status.bestPercent} percent',
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                passed ? Icons.verified : Icons.article_outlined,
                size: 24,
                color: passed ? sem.success : Theme.of(context).colorScheme.primary,
              ),
              const Spacer(),
              if (passed)
                _Pill(text: 'Passed', fg: sem.successFg, bg: sem.successTint)
              else if (status.attempted)
                _Pill(
                  text: '${status.bestPercent}%',
                  fg: sem.warnFg,
                  bg: sem.warnTint,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(test.title, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${test.questionCount} questions · ${test.needToPass} to pass',
            style: text.bodySmall,
          ),
        ],
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.fg, required this.bg});

  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}
