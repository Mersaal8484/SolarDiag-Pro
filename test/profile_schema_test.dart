import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/tool/profile_schema_validator.dart';

void main() {
  final schema = jsonDecode(
    File('device_profiles/profile.schema.json').readAsStringSync(),
  ) as Map<String, Object?>;
  const validator = ProfileSchemaValidator();

  test('every bundled profile satisfies the JSON schema', () {
    final profiles = Directory('device_profiles')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.json') &&
              !file.path.endsWith('profile.schema.json'),
        );
    for (final file in profiles) {
      final document = jsonDecode(file.readAsStringSync());
      expect(
        validator.validate(document, schema),
        isEmpty,
        reason: file.path,
      );
    }
  });

  test('invalid profile fixtures each violate the declared schema', () {
    final fixtures = Directory('test/fixtures/profiles_invalid')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));
    expect(fixtures, hasLength(4));

    for (final file in fixtures) {
      final document = jsonDecode(file.readAsStringSync());
      expect(
        validator.validate(document, schema),
        isNotEmpty,
        reason: file.path,
      );
    }
  });
}
