import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

@immutable
class SolarTokens extends ThemeExtension<SolarTokens> {
  const SolarTokens({
    required this.palette,
    required this.highContrast,
    required this.workshop,
    required this.reduceTransparency,
  });
  final SolarPalette palette;
  final bool highContrast;
  final bool workshop;
  final bool reduceTransparency;
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
    bool? reduceTransparency,
  }) => SolarTokens(
    palette: palette ?? this.palette,
    highContrast: highContrast ?? this.highContrast,
    workshop: workshop ?? this.workshop,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
  );
  @override
  SolarTokens lerp(covariant SolarTokens? other, double t) =>
      other == null || t < .5 ? this : other;
}

ThemeData solarTheme({
  required Brightness brightness,
  bool highContrast = false,
  bool workshop = false,
  bool reduceTransparency = false,
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
        reduceTransparency: reduceTransparency,
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
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(SolarRadius.card),
        side: BorderSide(
          color: palette.separator,
          width: highContrast ? 2 : .5,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: reduceTransparency
          ? palette.background
          : palette.background.withValues(alpha: .88),
      surfaceTintColor: palette.background.withValues(alpha: 0),
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: reduceTransparency
          ? palette.surface
          : palette.surface.withValues(alpha: .88),
      indicatorColor: palette.tint.withValues(alpha: .14),
      height: workshop ? 72 : 64,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: reduceTransparency
          ? palette.surface
          : palette.surface.withValues(alpha: .88),
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(0, workshop ? 56 : 44),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(SolarRadius.control),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, workshop ? 56 : 44),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(SolarRadius.control),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: Size(0, workshop ? 56 : 44),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(SolarRadius.control),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: Size.square(workshop ? 56 : 44)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, workshop ? 56 : 44)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SolarRadius.control),
        borderSide: BorderSide(color: palette.separator),
      ),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
}
