import 'package:flutter/material.dart';

@immutable
class SolarTokens extends ThemeExtension<SolarTokens> {
  const SolarTokens({
    required this.success,
    required this.warning,
    required this.simulated,
    required this.panel,
    required this.divider,
  });
  final Color success;
  final Color warning;
  final Color simulated;
  final Color panel;
  final Color divider;
  @override
  SolarTokens copyWith({
    Color? success,
    Color? warning,
    Color? simulated,
    Color? panel,
    Color? divider,
  }) => SolarTokens(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    simulated: simulated ?? this.simulated,
    panel: panel ?? this.panel,
    divider: divider ?? this.divider,
  );
  @override
  SolarTokens lerp(covariant SolarTokens? other, double t) => other == null
      ? this
      : SolarTokens(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
          simulated: Color.lerp(simulated, other.simulated, t)!,
          panel: Color.lerp(panel, other.panel, t)!,
          divider: Color.lerp(divider, other.divider, t)!,
        );
}

abstract final class SolarColors {
  static const ink = Color(0xFF101916);
  static const deep = Color(0xFF0B2E24);
  static const green = Color(0xFF1C8C65);
  static const lime = Color(0xFFD7F45B);
  static const mist = Color(0xFFF1F5EF);
  static const line = Color(0xFFDCE5DE);
  static const amber = Color(0xFFE8893E);
}

ThemeData solarTheme({
  required Brightness brightness,
  bool highContrast = false,
}) {
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF07130F) : SolarColors.mist;
  final surface = dark ? const Color(0xFF10231C) : Colors.white;
  final foreground = dark ? const Color(0xFFF0F5F1) : SolarColors.ink;
  final divider = dark ? const Color(0xFF29443A) : SolarColors.line;
  final scheme = ColorScheme.fromSeed(
    seedColor: SolarColors.green,
    brightness: brightness,
    primary: dark ? SolarColors.lime : SolarColors.deep,
    secondary: SolarColors.lime,
    surface: surface,
    contrastLevel: highContrast ? 1 : 0,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: background,
    colorScheme: scheme,
    extensions: [
      SolarTokens(
        success: const Color(0xFF35B982),
        warning: SolarColors.amber,
        simulated: SolarColors.lime,
        panel: surface,
        divider: divider,
      ),
    ],
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 38,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        color: foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
        color: foreground,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: foreground),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, color: foreground),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: divider, width: highContrast ? 2 : 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: SolarColors.lime,
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 350),
    ),
  );
}
