import 'dart:convert';
import 'dart:io';

void main() {
  final catalog =
      jsonDecode(File('design/icons.json').readAsStringSync())
          as Map<String, Object?>;
  final names = (catalog['icons'] as List).cast<String>();
  final directional = (catalog['directional'] as List).cast<String>().toSet();
  final directory = Directory('assets/icons')..createSync(recursive: true);
  for (var index = 0; index < names.length; index++) {
    final name = names[index];
    final variant = index % 4;
    final mark = switch (variant) {
      0 => '<path d="M5 15l4-4 3 3 7-7"/><path d="M16 7h3v3"/>',
      1 =>
        '<rect x="4" y="5" width="16" height="14" rx="2"/><path d="M8 12h8M12 8v8"/>',
      2 => '<circle cx="12" cy="12" r="7"/><path d="M12 8v4l3 2"/>',
      _ => '<path d="M4 13h4l2-5 4 9 2-4h4"/>',
    };
    File('${directory.path}/$name.svg').writeAsStringSync(
      '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">$mark</svg>',
    );
  }
  String identifier(String name) {
    final parts = name.split('-');
    return parts.first +
        parts
            .skip(1)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join();
  }

  final constants = names
      .map(
        (name) =>
            "  static const ${identifier(name)} = SolarIconData('$name', directional: ${directional.contains(name)});",
      )
      .join('\n');
  File('lib/design/solar_icons.g.dart').writeAsStringSync(
    '''// GENERATED FILE. Run: dart run tool/generate_icons.dart
class SolarIconData {
  const SolarIconData(this.name, {this.directional = false});
  final String name;
  final bool directional;
  String get asset => 'assets/icons/\$name.svg';
}

abstract final class SolarIcons {
$constants
  static const all = <SolarIconData>[$names];
}
'''
        .replaceFirst(
          '[$names]',
          '[${names.map((name) => identifier(name)).join(', ')}]',
        ),
  );
}
