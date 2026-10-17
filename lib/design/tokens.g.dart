// GENERATED FILE. Run: dart run tool/generate_tokens.dart
import 'package:flutter/material.dart';

abstract final class SolarSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
  static const double page = 48;
  static const double hero = 64;
  static const double readableWidth = 680;
}

abstract final class SolarRadius {
  static const double chip = 8;
  static const double control = 12;
  static const double card = 16;
  static const double hero = 22;
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
  static const SolarPalette light = SolarPalette(
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    labelPrimary: Color(0xFF1D1D1F),
    labelSecondary: Color(0xFF6E6E73),
    separator: Color(0xFFD2D2D7),
    tint: Color(0xFF0071E3),
    ok: Color(0xFF248A3D),
    warning: Color(0xFFB25000),
    critical: Color(0xFFD70015),
    info: Color(0xFF0A6EBD),
    simulated: Color(0xFF7C3AED),
  );
  static const SolarPalette dark = SolarPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceRaised: Color(0xFF2C2C2E),
    labelPrimary: Color(0xFFF5F5F7),
    labelSecondary: Color(0xFFA1A1A6),
    separator: Color(0xFF38383A),
    tint: Color(0xFF2997FF),
    ok: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    critical: Color(0xFFFF453A),
    info: Color(0xFF64D2FF),
    simulated: Color(0xFFBF5AF2),
  );
  static const Color energySolar = Color(0xFFFFB020);
  static const Color energyBattery = Color(0xFF30B35A);
  static const Color energyGrid = Color(0xFF3B82F6);
  static const Color energyLoad = Color(0xFFA855F7);
}
