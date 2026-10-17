import 'dart:convert';
import 'dart:io';

import 'package:solardiag_pro/protocol/device_profile.dart';

void main() {
  final files = Directory('device_profiles')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.json') &&
            !file.path.endsWith('profile.schema.json'),
      )
      .toList();
  var failed = false;
  for (final file in files) {
    try {
      final value = jsonDecode(file.readAsStringSync());
      if (value is! Map<String, Object?>) {
        throw const FormatException('Root must be an object.');
      }
      final profile = DeviceProfile.fromJson(value);
      if (profile.schemaVersion != 2) {
        throw const FormatException('Profile was not normalized to v2.');
      }
      stdout.writeln('valid: ${file.path}');
    } catch (error) {
      failed = true;
      stderr.writeln('invalid: ${file.path}: $error');
    }
  }
  if (failed) exitCode = 1;
}
