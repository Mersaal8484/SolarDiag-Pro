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
  static const ink = Color(0xFFF3F7FF);
  static const deep = Color(0xFF0B1930);
  static const green = Color(0xFF00D5FF);
  static const lime = Color(0xFF00D9A6);
  static const mist = Color(0xFF080F1F);
  static const line = Color(0xFF293C57);
  static const amber = Color(0xFFFFB547);
  static const onDark = Color(0xFFF3F7FF);
  static const onDarkStrong = Color(0xDDF3F7FF);
  static const onDarkMuted = Color(0xBBBCD1EA);
  static const onDarkFaint = Color(0x88A8BBD4);
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
        fontSize: 58,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displaySmall: base.copyWith(
        fontSize: 32,
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
        fontSize: 21,
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
        side: BorderSide(color: palette.separator, width: highContrast ? 2 : 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.labelPrimary,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.tint.withValues(alpha: .14),
      height: workshop ? 82 : 74,
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
    dividerTheme: DividerThemeData(color: palette.separator, thickness: 1),
    iconTheme: IconThemeData(color: palette.tint, size: 21),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: brightness == Brightness.dark
            ? const Color(0xFF061424)
            : Colors.white,
        backgroundColor: palette.tint,
        disabledBackgroundColor: palette.surfaceRaised,
        disabledForegroundColor: palette.labelSecondary,
        minimumSize: Size(0, workshop ? 56 : 48),
        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, workshop ? 56 : 48),
        side: BorderSide(color: palette.separator),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      floatingLabelStyle: TextStyle(color: palette.tint),
      hintStyle: TextStyle(color: palette.labelSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.separator),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.tint, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceRaised,
      selectedColor: palette.tint.withValues(alpha: .17),
      side: BorderSide(color: palette.separator),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: TextStyle(color: palette.labelPrimary),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.tint,
      textColor: palette.labelPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceRaised,
      contentTextStyle: TextStyle(color: palette.labelPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.tint),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.tint.withValues(alpha: .2)
              : palette.surface,
        ),
        foregroundColor: WidgetStatePropertyAll(palette.labelPrimary),
        side: WidgetStatePropertyAll(BorderSide(color: palette.separator)),
      ),
    ),
    visualDensity: workshop
        ? VisualDensity.comfortable
        : VisualDensity.standard,
  );
}
