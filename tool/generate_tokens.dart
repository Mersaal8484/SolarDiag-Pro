import 'dart:convert';
import 'dart:io';

void main() {
  Directory('lib/design').createSync(recursive: true);
  final json =
      jsonDecode(File('design/tokens.json').readAsStringSync())
          as Map<String, Object?>;
  final spacing = json['spacing'] as Map<String, Object?>;
  final radii = json['radii'] as Map<String, Object?>;
  final durations = json['durations_ms'] as Map<String, Object?>;
  String fields(Map<String, Object?> values, String type, String prefix) =>
      values.entries
          .map(
            (entry) =>
                '  static const $type $prefix${entry.key} = ${entry.value};',
          )
          .join('\n');
  String palette(String name) {
    final values = json[name] as Map<String, Object?>;
    return '  static const SolarPalette $name = SolarPalette(${values.entries.map((entry) => '${entry.key}: Color(0x${entry.value})').join(', ')});';
  }

  final output =
      '''// GENERATED FILE. Run: dart run tool/generate_tokens.dart
import 'package:flutter/material.dart';

abstract final class SolarSpace {
${fields(spacing, 'double', '')}
  static const double readableWidth = 680;
}

abstract final class SolarRadius {
${fields(radii, 'double', '')}
}

abstract final class SolarMotion {
${durations.entries.map((entry) => '  static const Duration ${entry.key} = Duration(milliseconds: ${entry.value});').join('\n')}
}

class SolarPalette {
  const SolarPalette({required this.background, required this.surface, required this.surfaceRaised, required this.labelPrimary, required this.labelSecondary, required this.separator, required this.tint, required this.ok, required this.warning, required this.critical, required this.info, required this.simulated});
  final Color background, surface, surfaceRaised, labelPrimary, labelSecondary, separator, tint, ok, warning, critical, info, simulated;
}

abstract final class SolarPalettes {
${palette('light')}
${palette('dark')}
  static const Color energySolar = Color(0x${(json['energy'] as Map)['solar']});
  static const Color energyBattery = Color(0x${(json['energy'] as Map)['battery']});
  static const Color energyGrid = Color(0x${(json['energy'] as Map)['grid']});
  static const Color energyLoad = Color(0x${(json['energy'] as Map)['load']});
}
''';
  File('lib/design/tokens.g.dart').writeAsStringSync(output);
}
