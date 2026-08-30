import 'package:flutter/material.dart';

/// A large, unmistakable primary action for the Home screen.
///
/// Icon plus a short label plus one line of plain-English explanation, sized
/// so it stays a comfortable target on a small phone and simply grows taller
/// when the OS text size is turned up.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onPressed;

  /// The single most prominent action on the screen.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = onPressed != null;

    final Color foreground = !enabled
        ? scheme.onSurfaceVariant
        : filled
            ? scheme.onPrimary
            : scheme.primary;
    final Color background = filled && enabled ? scheme.primary : Colors.transparent;

    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label. $description',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: filled
                  ? null
                  : Border.all(
                      color: enabled ? scheme.primary : scheme.outlineVariant,
                      width: 2,
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 34, color: foreground),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: theme.textTheme.headlineSmall?.copyWith(color: foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: filled && enabled
                              ? scheme.onPrimary.withValues(alpha: 0.92)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
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
