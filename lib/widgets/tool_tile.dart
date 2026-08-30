import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// A compact, icon-led entry point used on Home for Flashcards, Fix your
/// misses, Favorites and Statistics. Shows an optional count badge.
class ToolTile extends StatelessWidget {
  const ToolTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// A small count like "4" for Fix-your-misses, or null.
  final String? badge;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final Color color = tint ?? Theme.of(context).colorScheme.primary;
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      semanticLabel: badge == null ? label : '$label, $badge',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadii.controlR,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sem.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: text.bodySmall?.copyWith(
                      color: sem.onAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(label, style: text.titleMedium),
        ],
      ),
    );
  }
}
