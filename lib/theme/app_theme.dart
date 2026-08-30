import 'package:flutter/material.dart';

/// Visual language: **"Confident & Warm"** — trustworthy, rounded, reassuring
/// for a nervous, high-stakes audience.
///
/// Everything visual flows from the tokens below. To re-skin the app, a
/// developer changes only [AppColors] (the colour tokens), the two font
/// families in [AppTheme], and the two radii in [AppRadii] — the component kit
/// in `lib/widgets/` and every layout stay put.
///
/// Rules the theme also encodes for this audience:
///  * large, legible type by default (body 18–19sp, headings much larger),
///  * tap targets ≥ 48dp, primary actions ≥ 56dp,
///  * WCAG AA contrast on every text/background pair (verified), and
///  * [MediaQuery.textScaler] is never clamped — the OS text-size setting is
///    honoured all the way up.
abstract final class AppColors {
  // --- Brand ---------------------------------------------------------------
  /// Deep navy — the trustworthy base. Primary text and most UI tint.
  static const Color ink = Color(0xFF1C2B4A);

  /// Warm red — spent sparingly on the primary action and focus.
  static const Color accent = Color(0xFFD33F49);

  /// Lifted red for dark surfaces (keeps AA on deep navy).
  static const Color accentDark = Color(0xFFF07980);

  // --- Light surfaces ------------------------------------------------------
  static const Color background = Color(0xFFF7F8FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF5C6472);
  static const Color hairline = Color(0xFFECEFF3);

  // --- Dark surfaces --------------------------------------------------------
  static const Color backgroundDark = Color(0xFF141B2E);
  static const Color cardDark = Color(0xFF1E2740);
  static const Color textDark = Color(0xFFEAECF3);
  static const Color mutedDark = Color(0xFF9AA4BC);
  static const Color hairlineDark = Color(0xFF2C3757);

  // --- Success / "correct" (light) -----------------------------------------
  /// Green line + tint. Reused by the option tiles' "correct" state.
  static const Color correctBorder = Color(0xFF3E9B6B);
  static const Color correctBg = Color(0xFFE7F3EC);
  static const Color correctFg = Color(0xFF14532D);

  // --- Success / "correct" (dark) ------------------------------------------
  static const Color correctFgDark = Color(0xFF8FDDB0);
  static const Color correctBgDark = Color(0xFF12311F);

  // --- "Not quite" — warm amber, never alarm-red (light) -------------------
  /// A wrong answer is information, not failure, so it reads amber.
  static const Color reviewBorder = Color(0xFFB4690E);
  static const Color reviewBg = Color(0xFFFDF1E3);
  static const Color reviewFg = Color(0xFF7A3E00);

  // --- "Not quite" (dark) --------------------------------------------------
  static const Color reviewFgDark = Color(0xFFF5C892);
  static const Color reviewBgDark = Color(0xFF3A2609);

  // --- Legacy aliases kept so earlier widgets need no edits ----------------
  static const Color navy = ink;
  static const Color flagRed = accent;
  static const Color surfaceLight = background;
  static const Color surfaceTintLight = card;
}

/// Semantic colours resolved per brightness, for the reusable component kit.
///
/// Widgets read `Theme.of(context).extension<AppSemantics>()!` instead of
/// switching on brightness themselves, so light and dark stay in lockstep.
@immutable
class AppSemantics extends ThemeExtension<AppSemantics> {
  const AppSemantics({
    required this.accent,
    required this.onAccent,
    required this.card,
    required this.muted,
    required this.hairline,
    required this.success,
    required this.successTint,
    required this.successFg,
    required this.warnFg,
    required this.warnTint,
    required this.warnBorder,
  });

  final Color accent;
  final Color onAccent;
  final Color card;
  final Color muted;
  final Color hairline;
  final Color success;
  final Color successTint;
  final Color successFg;
  final Color warnFg;
  final Color warnTint;
  final Color warnBorder;

  static const AppSemantics light = AppSemantics(
    accent: AppColors.accent,
    onAccent: Colors.white,
    card: AppColors.card,
    muted: AppColors.muted,
    hairline: AppColors.hairline,
    success: AppColors.correctBorder,
    successTint: AppColors.correctBg,
    successFg: AppColors.correctFg,
    warnFg: AppColors.reviewFg,
    warnTint: AppColors.reviewBg,
    warnBorder: AppColors.reviewBorder,
  );

  static const AppSemantics dark = AppSemantics(
    accent: AppColors.accentDark,
    onAccent: Color(0xFF33060A),
    card: AppColors.cardDark,
    muted: AppColors.mutedDark,
    hairline: AppColors.hairlineDark,
    success: AppColors.correctBorder,
    successTint: AppColors.correctBgDark,
    successFg: AppColors.correctFgDark,
    warnFg: AppColors.reviewFgDark,
    warnTint: AppColors.reviewBgDark,
    warnBorder: AppColors.reviewBorder,
  );

  @override
  AppSemantics copyWith({
    Color? accent,
    Color? onAccent,
    Color? card,
    Color? muted,
    Color? hairline,
    Color? success,
    Color? successTint,
    Color? successFg,
    Color? warnFg,
    Color? warnTint,
    Color? warnBorder,
  }) =>
      AppSemantics(
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        card: card ?? this.card,
        muted: muted ?? this.muted,
        hairline: hairline ?? this.hairline,
        success: success ?? this.success,
        successTint: successTint ?? this.successTint,
        successFg: successFg ?? this.successFg,
        warnFg: warnFg ?? this.warnFg,
        warnTint: warnTint ?? this.warnTint,
        warnBorder: warnBorder ?? this.warnBorder,
      );

  @override
  AppSemantics lerp(covariant AppSemantics? other, double t) {
    if (other == null) return this;
    return AppSemantics(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      success: Color.lerp(success, other.success, t)!,
      successTint: Color.lerp(successTint, other.successTint, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      warnFg: Color.lerp(warnFg, other.warnFg, t)!,
      warnTint: Color.lerp(warnTint, other.warnTint, t)!,
      warnBorder: Color.lerp(warnBorder, other.warnBorder, t)!,
    );
  }
}

/// Convenience accessor for the semantic palette.
extension AppSemanticsX on BuildContext {
  AppSemantics get sem => Theme.of(this).extension<AppSemantics>() ?? AppSemantics.light;
}

/// Shape tokens. Card radius and control radius are the two values a re-skin
/// touches; everything else is derived.
abstract final class AppRadii {
  static const double card = 20;
  static const double control = 13;

  static BorderRadius get cardR => BorderRadius.circular(card);
  static BorderRadius get controlR => BorderRadius.circular(control);
}

/// Minimum height for a primary action. Actions grow past this as text scales.
const double kPrimaryActionHeight = 56;

/// Minimum tap target, per WCAG and the Material guidelines.
const double kMinTapTarget = 48;

/// Standard page padding.
const EdgeInsets kPagePadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

/// Soft, low card shadow — depth without harsh borders.
List<BoxShadow> appCardShadow(Brightness brightness) => brightness == Brightness.light
    ? const <BoxShadow>[
        BoxShadow(color: Color(0x141C2B4A), blurRadius: 18, offset: Offset(0, 6)),
        BoxShadow(color: Color(0x0A1C2B4A), blurRadius: 3, offset: Offset(0, 1)),
      ]
    : const <BoxShadow>[
        BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
      ];

abstract final class AppTheme {
  /// Headings and the greeting: rounded, friendly, confident.
  static const String displayFont = 'Nunito';

  /// Body text: the sans-serif sibling, highly legible at length.
  static const String bodyFont = 'NunitoSans';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final AppSemantics sem = isLight ? AppSemantics.light : AppSemantics.dark;

    final Color surface = isLight ? AppColors.background : AppColors.backgroundDark;
    final Color onSurface = isLight ? AppColors.ink : AppColors.textDark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      brightness: brightness,
    ).copyWith(
      primary: isLight ? AppColors.ink : const Color(0xFFAFC4EE),
      onPrimary: isLight ? Colors.white : const Color(0xFF0A1526),
      secondary: sem.accent,
      onSecondary: sem.onAccent,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: sem.card,
      onSurfaceVariant: sem.muted,
      outline: sem.hairline,
      outlineVariant: sem.hairline,
      error: sem.accent,
    );

    final TextTheme text = _textTheme(onSurface, sem.muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      fontFamily: bodyFont,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[sem],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      // FilledButton is Material's primary action, so it carries the accent.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: sem.accent,
          foregroundColor: sem.onAccent,
          minimumSize: const Size.fromHeight(kPrimaryActionHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.controlR),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(kMinTapTarget + 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: text.labelLarge,
          side: BorderSide(color: sem.hairline, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.controlR),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          textStyle: text.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 14,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium,
        iconColor: scheme.primary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: sem.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardR),
      ),
      dividerTheme: DividerThemeData(color: sem.hairline, space: 1, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? sem.accent : null),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? sem.accent.withValues(alpha: 0.35) : null),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyLarge?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.controlR),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearMinHeight: 12,
        color: sem.accent,
        linearTrackColor: sem.hairline,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sem.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardR),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sem.card,
        side: BorderSide(color: sem.hairline, width: 1.5),
        labelStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  /// Nunito display for the big moments, Nunito Sans for reading. Larger than
  /// Material defaults throughout, because small print is the biggest barrier.
  static TextTheme _textTheme(Color onSurface, Color muted) {
    TextStyle display(double size, FontWeight weight) => TextStyle(
          fontFamily: displayFont,
          fontSize: size,
          fontWeight: weight,
          color: onSurface,
          height: 1.15,
        );
    TextStyle body(double size, FontWeight weight, {double height = 1.45}) => TextStyle(
          fontFamily: bodyFont,
          fontSize: size,
          fontWeight: weight,
          color: onSurface,
          height: height,
        );

    return TextTheme(
      displaySmall: display(38, FontWeight.w800),
      headlineMedium: display(30, FontWeight.w800),
      headlineSmall: display(25, FontWeight.w800),
      titleLarge: display(23, FontWeight.w800),
      titleMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.3,
      ),
      titleSmall: body(17, FontWeight.w700),
      bodyLarge: body(19, FontWeight.w400),
      bodyMedium: body(17, FontWeight.w400),
      bodySmall: body(15, FontWeight.w400, height: 1.4).copyWith(color: muted),
      labelLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
    );
  }
}
