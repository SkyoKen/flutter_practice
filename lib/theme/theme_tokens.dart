import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color ink;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color cyan;
  final Color amber;
  final Color danger;
  final bool useHardShadow;
  final double strongBorderWidth;
  final double radius;

  const AppThemeTokens({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.ink,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.cyan,
    required this.amber,
    required this.danger,
    required this.useHardShadow,
    required this.strongBorderWidth,
    required this.radius,
  });

  List<BoxShadow> hardShadow({Offset offset = const Offset(5, 5)}) {
    if (!useHardShadow) return const [];
    return [
      BoxShadow(
        color: ink,
        offset: offset,
        blurRadius: 0,
      ),
    ];
  }

  List<BoxShadow> softGlow(Color color) {
    if (useHardShadow) return const [];
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.28),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  @override
  AppThemeTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? ink,
    Color? border,
    Color? accent,
    Color? accentSoft,
    Color? cyan,
    Color? amber,
    Color? danger,
    bool? useHardShadow,
    double? strongBorderWidth,
    double? radius,
  }) {
    return AppThemeTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      ink: ink ?? this.ink,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      cyan: cyan ?? this.cyan,
      amber: amber ?? this.amber,
      danger: danger ?? this.danger,
      useHardShadow: useHardShadow ?? this.useHardShadow,
      strongBorderWidth: strongBorderWidth ?? this.strongBorderWidth,
      radius: radius ?? this.radius,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      useHardShadow: t < 0.5 ? useHardShadow : other.useHardShadow,
      strongBorderWidth:
          lerpDouble(strongBorderWidth, other.strongBorderWidth, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
    );
  }
}
