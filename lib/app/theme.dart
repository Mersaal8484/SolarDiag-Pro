import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

@immutable
class SolarTokens extends ThemeExtension<SolarTokens> {
  const SolarTokens({
    required this.palette,
    required this.highContrast,
    required this.workshop,
  });
  final SolarPalette palette;
  final bool highContrast;
  final bool workshop;
  Color get success => palette.ok;
  Color get warning => palette.warning;
  Color get simulated => palette.simulated;
  Color get panel => palette.surface;
  Color get divider => palette.separator;
  double get minimumTarget => workshop ? 56 : 44;
  @override
  SolarTokens copyWith({
    SolarPalette? palette,
    bool? highContrast,
    bool? workshop,
  }) => SolarTokens(
    palette: palette ?? this.palette,
    highContrast: highContrast ?? this.highContrast,
    workshop: workshop ?? this.workshop,
  );
  @override
  SolarTokens lerp(covariant SolarTokens? other, double t) =>
      other == null || t < .5 ? this : other;
}

abstract final class SolarColors {
  static const ink = Color(0xFF1D1D1F);
  static const deep = Color(0xFF1D1D1F);
  static const green = Color(0xFF0071E3);
  static const lime = Color(0xFFBF5AF2);
  static const mist = Color(0xFFF5F5F7);
  static const line = Color(0xFFD2D2D7);
  static const amber = Color(0xFFB25000);
  static const onDark = Color(0xFFFFFFFF);
  static const onDarkStrong = Color(0xB3FFFFFF);
  static const onDarkMuted = Color(0x99FFFFFF);
  static const onDarkFaint = Color(0x8AFFFFFF);
  static const transparent = Color(0x00000000);
}

ThemeData solarTheme({
  required Brightness brightness,
  bool highContrast = false,
  bool workshop = false,
}) {
  final palette = brightness == Brightness.dark
      ? SolarPalettes.dark
      : SolarPalettes.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.tint,
    brightness: brightness,
    surface: palette.surface,
    error: palette.critical,
    contrastLevel: highContrast ? 1 : 0,
  );
  final base = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['IBM Plex Sans Arabic'],
    color: palette.labelPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    colorScheme: scheme,
    fontFamily: 'Inter',
    fontFamilyFallback: const ['IBM Plex Sans Arabic'],
    extensions: [
      SolarTokens(
        palette: palette,
        highContrast: highContrast,
        workshop: workshop,
      ),
    ],
    textTheme: TextTheme(
      displayLarge: base.copyWith(
        fontSize: 68,
        height: 1,
        fontWeight: FontWeight.w300,
        letterSpacing: -2.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displaySmall: base.copyWith(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineMedium: base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -.7,
      ),
      headlineSmall: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -.4,
      ),
      titleMedium: base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 17, height: 1.45),
      bodyMedium: base.copyWith(fontSize: 15, height: 1.45),
      labelLarge: base.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodySmall: base.copyWith(fontSize: 13, color: palette.labelSecondary),
      labelSmall: base.copyWith(fontSize: 12, color: palette.labelSecondary),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SolarRadius.card),
        side: BorderSide(
          color: palette.separator,
          width: highContrast ? 2 : .5,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.tint.withValues(alpha: .14),
      height: workshop ? 72 : 64,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.tint.withValues(alpha: .14),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    tooltipTheme: const TooltipThemeData(waitDuration: SolarMotion.normal),
    visualDensity: workshop
        ? VisualDensity.comfortable
        : VisualDensity.standard,
  );
}
