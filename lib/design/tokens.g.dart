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
  static const Duration springResponse = Duration(milliseconds: 350);
  static const double springDamping = 0.85;
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

class SolarEnergyPalette {
  const SolarEnergyPalette({
    required this.solar,
    required this.battery,
    required this.grid,
    required this.load,
  });
  final Color solar, battery, grid, load;
}

abstract final class SolarPalettes {
  static const SolarPalette light = SolarPalette(
    background: Color(0xFFF2F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEAF1F9),
    labelPrimary: Color(0xFF132641),
    labelSecondary: Color(0xFF53677F),
    separator: Color(0xFFD8E2EF),
    tint: Color(0xFF066FBE),
    ok: Color(0xFF008C6B),
    warning: Color(0xFFAC680B),
    critical: Color(0xFFCA3754),
    info: Color(0xFF0C77C5),
    simulated: Color(0xFF6854C9),
  );
  static const SolarPalette dark = SolarPalette(
    background: Color(0xFF080F1F),
    surface: Color(0xFF111D32),
    surfaceRaised: Color(0xFF192B46),
    labelPrimary: Color(0xFFF3F7FF),
    labelSecondary: Color(0xFFA8BAD2),
    separator: Color(0xFF2B405C),
    tint: Color(0xFF00D5FF),
    ok: Color(0xFF00D9A6),
    warning: Color(0xFFFFB547),
    critical: Color(0xFFFF5263),
    info: Color(0xFF59A8FF),
    simulated: Color(0xFFB7A0FF),
  );
  static const SolarEnergyPalette energyLight = SolarEnergyPalette(
    solar: Color(0xFF9A6700),
    battery: Color(0xFF187A38),
    grid: Color(0xFF1261A0),
    load: Color(0xFF7A3EA1),
  );
  static const SolarEnergyPalette energyDark = SolarEnergyPalette(
    solar: Color(0xFFFFB547),
    battery: Color(0xFF00D9A6),
    grid: Color(0xFF59A8FF),
    load: Color(0xFFC198FF),
  );
}
