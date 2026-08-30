import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The one card surface used everywhere: card colour, radius-20 corners, and a
/// soft low shadow instead of a hard border.
///
/// Pass [onTap] to make it a large tappable target (with a gentle press ripple)
/// or leave it null for a static container.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.border,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BoxBorder? border;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final Color background = color ?? context.sem.card;

    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.cardR,
        border: border,
        boxShadow: onTap == null && border != null ? null : appCardShadow(brightness),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return semanticLabel == null
          ? content
          : Semantics(container: true, label: semanticLabel, child: content);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: background,
        borderRadius: AppRadii.cardR,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadii.cardR,
              border: border,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
