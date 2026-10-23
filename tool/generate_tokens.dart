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
  final spring = json['spring'] as Map<String, Object?>;
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

  String energyPalette(String name) {
    final values = json[name] as Map<String, Object?>;
    return '  static const SolarEnergyPalette $name = SolarEnergyPalette(${values.entries.map((entry) => '${entry.key}: Color(0x${entry.value})').join(', ')});';
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
  static const Duration springResponse = Duration(milliseconds: ${spring['response_ms']});
  static const double springDamping = ${spring['damping']};
}

class SolarPalette {
  const SolarPalette({required this.background, required this.surface, required this.surfaceRaised, required this.labelPrimary, required this.labelSecondary, required this.separator, required this.tint, required this.ok, required this.warning, required this.critical, required this.info, required this.simulated});
  final Color background, surface, surfaceRaised, labelPrimary, labelSecondary, separator, tint, ok, warning, critical, info, simulated;
}

class SolarEnergyPalette {
  const SolarEnergyPalette({required this.solar, required this.battery, required this.grid, required this.load});
  final Color solar, battery, grid, load;
}

abstract final class SolarPalettes {
${palette('light')}
${palette('dark')}
${energyPalette('energyLight')}
${energyPalette('energyDark')}
}
''';
  File('lib/design/tokens.g.dart').writeAsStringSync(output);
}
