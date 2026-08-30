import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's primary call to action: a full-width, accent-filled, radius-13
/// button with an optional leading icon and a gentle press state.
///
/// A [PrimaryButton.tonal] variant carries the same shape but a quiet surface,
/// for secondary actions that should not compete with the main one.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _tonal = false;

  const PrimaryButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _tonal = true;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool _tonal;

  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[Icon(icon, size: 24), const SizedBox(width: 10)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );

    if (_tonal) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: sem.accent.withValues(alpha: 0.08),
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: sem.hairline, width: 1.5),
        ),
        child: child,
      );
    }
    return FilledButton(onPressed: onPressed, child: child);
  }
}
