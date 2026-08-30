import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A confidence meter with a smooth fill animation — the one place the design
/// spends real boldness.
///
/// Used for the Home readiness meter and per-category mastery bars. The fill
/// animates from its previous value; motion is skipped when the OS has
/// reduce-motion turned on.
class StatMeter extends StatelessWidget {
  const StatMeter({
    super.key,
    required this.value,
    this.height = 14,
    this.color,
    this.trackColor,
  }) : assert(value >= 0 && value <= 1);

  /// 0..1.
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final Color fill = color ?? sem.accent;
    final bool animate = !MediaQuery.of(context).disableAnimations;

    return Semantics(
      value: '${(value * 100).round()} percent',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double full = constraints.maxWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: Stack(
              children: <Widget>[
                Container(height: height, color: trackColor ?? sem.hairline),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
                  duration: animate ? const Duration(milliseconds: 700) : Duration.zero,
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double v, _) => Container(
                    height: height,
                    width: full * v,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[fill.withValues(alpha: 0.82), fill],
                      ),
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A circular percentage ring, for the readiness headline on Home.
class StatRing extends StatelessWidget {
  const StatRing({super.key, required this.value, this.size = 116, this.label});

  final double value; // 0..1
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final AppSemantics sem = context.sem;
    final TextTheme text = Theme.of(context).textTheme;
    final bool animate = !MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: label,
      value: '${(value * 100).round()} percent',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.clamp(0, 1)),
          duration: animate ? const Duration(milliseconds: 800) : Duration.zero,
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double v, _) => Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 11,
                  strokeCap: StrokeCap.round,
                  backgroundColor: sem.hairline,
                  valueColor: AlwaysStoppedAnimation<Color>(sem.accent),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('${(v * 100).round()}%',
                      style: text.headlineSmall, textScaler: TextScaler.noScaling),
                  if (label != null)
                    Text(label!, style: text.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
