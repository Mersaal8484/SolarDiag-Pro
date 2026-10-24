import 'dart:convert';
import 'dart:io';

import 'package:solardiag_pro/protocol/device_profile.dart';
import 'profile_schema_validator.dart';

void main() {
  final schemaValue = jsonDecode(
    File('device_profiles/profile.schema.json').readAsStringSync(),
  );
  if (schemaValue is! Map<String, Object?>) {
    stderr.writeln('invalid: device_profiles/profile.schema.json: root must be an object.');
    exitCode = 1;
    return;
  }
  const schemaValidator = ProfileSchemaValidator();
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
      final schemaErrors = schemaValidator.validate(value, schemaValue);
      if (schemaErrors.isNotEmpty) {
        throw FormatException(schemaErrors.join('; '));
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
