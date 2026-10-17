import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/parameters/parameter_backup.dart';

void main() {
  test('backup comparison reports changed, missing, and added values', () {
    final backup = ParameterBackup(
      schemaVersion: 1,
      profileId: 'profile',
      deviceIdentity: 'device',
      firmware: '1',
      capturedAt: DateTime.utc(2026, 10, 18),
      values: const {'charge_limit': 55.2, 'service_mode': 1},
    );

    final differences = backup.compare(const {
      'charge_limit': 54.8,
      'new_parameter': 7,
    });

    expect(differences.map((item) => item.parameterId), [
      'charge_limit',
      'new_parameter',
      'service_mode',
    ]);
    expect(differences, everyElement(isA<ParameterDifference>()));
    expect(differences.where((item) => item.changed), hasLength(3));
    expect(differences[1].backupValue, isNull);
    expect(differences[2].currentValue, isNull);
  });

  test('identical backup comparison remains unchanged', () {
    final backup = ParameterBackup(
      schemaVersion: 1,
      profileId: 'profile',
      deviceIdentity: 'device',
      firmware: '1',
      capturedAt: DateTime.utc(2026, 10, 18),
      values: const {'charge_limit': 55.2},
    );

    expect(backup.compare(backup.values).single.changed, isFalse);
  });
}
