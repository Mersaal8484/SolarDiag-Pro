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
    fontFamily: 'Roboto',
    fontFamilyFallback: const ['Noto Sans Arabic', 'Arial'],
    color: palette.labelPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    fontFamilyFallback: const ['Noto Sans Arabic', 'Arial'],
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
        fontSize: 60,
        height: 1,
        fontWeight: FontWeight.w300,
        letterSpacing: -2.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displaySmall: base.copyWith(
        fontSize: 33,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineMedium: base.copyWith(
        fontSize: 27,
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
        side: BorderSide(color: palette.separator, width: highContrast ? 2 : 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: palette.background.withValues(alpha: 0),
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.tint.withValues(alpha: .17),
      height: workshop ? 78 : 70,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.tint.withValues(alpha: .17),
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
      filled: true,
      fillColor: palette.surfaceRaised.withValues(alpha: .72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      floatingLabelStyle: TextStyle(
        color: palette.tint,
        fontWeight: FontWeight.w700,
      ),
      labelStyle: TextStyle(color: palette.labelSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.separator),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.tint, width: 1.6),
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.separator, thickness: 1),
    iconTheme: IconThemeData(color: palette.tint, size: 22),
    listTileTheme: ListTileThemeData(
      iconColor: palette.tint,
      textColor: palette.labelPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceRaised,
      selectedColor: palette.tint.withValues(alpha: .18),
      labelStyle: TextStyle(color: palette.labelPrimary),
      side: BorderSide(color: palette.separator),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceRaised,
      contentTextStyle: TextStyle(color: palette.labelPrimary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.tint
            : palette.labelSecondary,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: palette.tint,
      unselectedLabelColor: palette.labelSecondary,
      indicatorColor: palette.tint,
      dividerColor: palette.separator,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.tint,
      linearTrackColor: palette.surfaceRaised,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
}
