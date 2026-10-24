// GENERATED FILE. Run: dart run tool/generate_tokens.dart
import 'package:flutter/material.dart';

abstract final class SolarSpace {
  static const double xs = 5;
  static const double sm = 9;
  static const double md = 13;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 26;
  static const double section = 32;
  static const double page = 48;
  static const double hero = 64;
  static const double readableWidth = 680;
}

abstract final class SolarRadius {
  static const double chip = 13;
  static const double control = 16;
  static const double card = 23;
  static const double hero = 28;
  static const double sheet = 28;
}

abstract final class SolarMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

class SolarPalette {
  const SolarPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.separator,
    required this.tint,
    required this.ok,
    required this.warning,
    required this.critical,
    required this.info,
    required this.simulated,
  });
  final Color background,
      surface,
      surfaceRaised,
      labelPrimary,
      labelSecondary,
      separator,
      tint,
      ok,
      warning,
      critical,
      info,
      simulated;
}

abstract final class SolarPalettes {
  // Precision Engineering: two accessible variants of one industrial design system.
  // The application launches dark-first; light mode remains available for outdoor use.
  static const SolarPalette light = SolarPalette(
    background: Color(0xFFF0F4FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE8EFF9),
    labelPrimary: Color(0xFF101E35),
    labelSecondary: Color(0xFF536781),
    separator: Color(0xFFD8E3F0),
    tint: Color(0xFF0868C9),
    ok: Color(0xFF067B66),
    warning: Color(0xFFA8630B),
    critical: Color(0xFFB72E47),
    info: Color(0xFF0868C9),
    simulated: Color(0xFF7856C5),
  );
  static const SolarPalette dark = SolarPalette(
    background: Color(0xFF080F1F),
    surface: Color(0xFF111D32),
    surfaceRaised: Color(0xFF182840),
    labelPrimary: Color(0xFFF3F7FF),
    labelSecondary: Color(0xFF99ADC9),
    separator: Color(0xFF293C57),
    tint: Color(0xFF00D5FF),
    ok: Color(0xFF00D9A6),
    warning: Color(0xFFFFB547),
    critical: Color(0xFFFF5263),
    info: Color(0xFF64A6FF),
    simulated: Color(0xFFB39AFF),
  );
  static const Color energySolar = Color(0xFFFFB547);
  static const Color energyBattery = Color(0xFF00D9A6);
  static const Color energyGrid = Color(0xFF3478F6);
  static const Color energyLoad = Color(0xFFB39AFF);
}
