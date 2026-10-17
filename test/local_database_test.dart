import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/parameters/parameter_backup.dart';
import 'package:solardiag_pro/persistence/local_database.dart';

void main() {
  test('SQLite persists and updates diagnostic session records', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final started = DateTime.utc(2026, 10, 18, 8);
    database.saveSession(
      DiagnosticSessionRecord(
        id: 'session-1',
        startedAt: started,
        updatedAt: started,
        scenario: 'healthy',
        simulated: true,
        snapshotJson: '{"soc":78}',
        dataHash: 'hash-1',
      ),
    );
    database.saveSession(
      DiagnosticSessionRecord(
        id: 'session-1',
        startedAt: started,
        updatedAt: started.add(const Duration(seconds: 1)),
        scenario: 'gradualImbalance',
        simulated: true,
        snapshotJson: '{"soc":77}',
        dataHash: 'hash-2',
      ),
    );

    final records = database.listSessions();
    expect(records, hasLength(1));
    expect(records.single.scenario, 'gradualImbalance');
    expect(records.single.dataHash, 'hash-2');
    expect(records.single.simulated, isTrue);
  });

  test('SQLite round-trips parameter backups without numeric loss', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final capturedAt = DateTime.utc(2026, 10, 18, 9);
    database.saveBackup(
      ParameterBackup(
        schemaVersion: 1,
        profileId: 'profile',
        deviceIdentity: 'device',
        firmware: '1.0',
        capturedAt: capturedAt,
        values: const {'charge_limit': 55.2, 'service_mode': 1},
      ),
    );

    final backups = database.listBackups();
    expect(backups, hasLength(1));
    expect(backups.single.capturedAt, capturedAt);
    expect(backups.single.values['charge_limit'], 55.2);
    expect(backups.single.values['service_mode'], 1);
  });

  test('SQLite persists boolean application settings', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);

    expect(database.getBool('onboarding_complete'), isFalse);
    database.setBool('onboarding_complete', true);
    expect(database.getBool('onboarding_complete'), isTrue);
  });
}
