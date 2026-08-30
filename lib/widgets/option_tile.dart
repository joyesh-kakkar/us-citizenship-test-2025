import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// How an option should look right now.
enum OptionStatus {
  /// Not answered yet.
  idle,

  /// Answered, and this is the selected answer (Test mode, before grading).
  selected,

  /// Answered, and this is the correct option.
  correct,

  /// Answered, and this is the wrong option the user tapped.
  chosenWrong,

  /// Answered, and this option is simply not the answer.
  dimmed,
}

/// One tappable multiple-choice option.
///
/// The tile grows with its text rather than clipping it, and every state is
/// signalled by an icon *and* a word as well as colour — never colour alone.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.status,
    required this.onTap,
    this.index,
  });

  final String label;
  final OptionStatus status;
  final VoidCallback? onTap;

  /// Position in the list, used only for the screen-reader label.
  final int? index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isLight = theme.brightness == Brightness.light;

    final (Color border, Color background, Color foreground, IconData? icon, String? tag) =
        switch (status) {
      OptionStatus.idle => (
          scheme.outlineVariant,
          Colors.transparent,
          scheme.onSurface,
          null,
          null,
        ),
      OptionStatus.selected => (
          scheme.primary,
          scheme.primary.withValues(alpha: 0.10),
          scheme.onSurface,
          Icons.radio_button_checked,
          'Your answer',
        ),
      OptionStatus.correct => (
          AppColors.correctBorder,
          isLight ? AppColors.correctBg : AppColors.correctBgDark,
          isLight ? AppColors.correctFg : AppColors.correctFgDark,
          Icons.check_circle,
          'Correct answer',
        ),
      OptionStatus.chosenWrong => (
          AppColors.reviewBorder,
          isLight ? AppColors.reviewBg : AppColors.reviewBgDark,
          isLight ? AppColors.reviewFg : AppColors.reviewFgDark,
          Icons.cancel_outlined,
          'You chose this',
        ),
      OptionStatus.dimmed => (
          scheme.outlineVariant,
          Colors.transparent,
          scheme.onSurfaceVariant,
          null,
          null,
        ),
    };

    return Semantics(
      button: onTap != null,
      selected: status == OptionStatus.selected || status == OptionStatus.chosenWrong,
      label: <String?>[
        if (index != null) 'Option ${index! + 1}',
        label,
        tag,
      ].whereType<String>().join('. '),
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            // A minimum: the tile stretches as the text wraps.
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
                width: status == OptionStatus.idle || status == OptionStatus.dimmed ? 1.5 : 2.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: foreground,
                          fontWeight:
                              status == OptionStatus.correct ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      if (tag != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          tag,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (icon != null) ...<Widget>[
                  const SizedBox(width: 12),
                  Icon(icon, color: foreground, size: 28),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
