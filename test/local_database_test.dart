import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/contribution/lifecycle.dart';
import 'package:solardiag_pro/parameters/parameter_backup.dart';
import 'package:solardiag_pro/persistence/local_database.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('app settings persist string and boolean design preferences', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);

    database
      ..setSetting('language', 'ar')
      ..setSetting('theme_mode', 'dark')
      ..setSetting('digit_preference', 'arabicIndic')
      ..setBool('workshop_mode', true)
      ..setBool('time_axis_ltr', false);

    expect(database.getSetting('language'), 'ar');
    expect(database.getSetting('theme_mode'), 'dark');
    expect(database.getSetting('digit_preference'), 'arabicIndic');
    expect(database.getBool('workshop_mode'), isTrue);
    expect(database.getBool('time_axis_ltr', defaultValue: true), isFalse);
  });

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

  test('migration 7 adds telemetry samples to a version 6 database', () {
    final directory = Directory.systemTemp.createTempSync(
      'solardiag-migration-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}legacy.sqlite';
    final legacy = sqlite3.open(path);
    legacy.execute('''
      CREATE TABLE diagnostic_sessions (
        id TEXT NOT NULL PRIMARY KEY,
        started_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        scenario TEXT NOT NULL,
        simulated INTEGER NOT NULL,
        snapshot_json TEXT NOT NULL,
        data_hash TEXT NOT NULL
      ) STRICT;
    ''');
    legacy.userVersion = 6;
    legacy.close();

    final database = LocalDatabase.openForTest(path);
    addTearDown(database.close);
    expect(database.schemaVersionForTest, 7);
    final now = DateTime.utc(2026, 10, 24);
    database.saveSession(
      DiagnosticSessionRecord(
        id: 'migrated-session',
        startedAt: now,
        updatedAt: now,
        scenario: 'healthy',
        simulated: true,
        snapshotJson: '{"soc":70}',
        dataHash: 'legacy-hash',
      ),
    );
    database.saveTelemetrySample(
      sessionId: 'migrated-session',
      capturedAt: now,
      snapshotJson: '{"soc":70}',
      qualityFlags: const {'soc': 'good'},
    );
    expect(database.listTelemetrySamples('migrated-session'), hasLength(1));
    expect(database.verifyTelemetryChain('migrated-session'), isTrue);
  });

  test(
    'telemetry retention downsamples old values and preserves hash chain',
    () {
      final database = LocalDatabase.inMemory(
        telemetryRetentionPolicy: const TelemetryRetentionPolicy(
          fullResolutionWindow: Duration(minutes: 10),
          downsampleBucket: Duration(minutes: 5),
          maximumAge: Duration(days: 1),
        ),
      );
      addTearDown(database.close);
      final start = DateTime.utc(2026, 10, 24, 8);
      database.saveSession(
        DiagnosticSessionRecord(
          id: 'retention-session',
          startedAt: start,
          updatedAt: start,
          scenario: 'healthy',
          simulated: true,
          snapshotJson: '{"soc":70}',
          dataHash: 'initial',
        ),
      );
      for (var minute = 0; minute < 3; minute++) {
        database.saveTelemetrySample(
          sessionId: 'retention-session',
          capturedAt: start.add(Duration(minutes: minute)),
          snapshotJson: '{"soc":${70 + minute}}',
          qualityFlags: const {'soc': 'good'},
        );
      }
      database.saveTelemetrySample(
        sessionId: 'retention-session',
        capturedAt: start.add(const Duration(minutes: 20)),
        snapshotJson: '{"soc":75}',
        qualityFlags: const {'soc': 'good'},
      );

      final samples = database.listTelemetrySamples('retention-session');
      expect(samples, hasLength(2));
      expect(samples.first.isAggregate, isTrue);
      final aggregate = jsonDecode(samples.first.aggregateJson!) as Map;
      final soc = (aggregate['series'] as Map)['soc'] as Map;
      expect(soc['min'], 70);
      expect(soc['max'], 72);
      expect(soc['mean'], 71);
      expect(database.verifyTelemetryChain('retention-session'), isTrue);

      database.rawExecuteForTest(
        "UPDATE telemetry_samples SET snapshot_json = '{\"soc\":999}' "
        "WHERE session_id = 'retention-session' AND is_aggregate = 0",
      );
      expect(database.verifyTelemetryChain('retention-session'), isFalse);
    },
  );

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

  test('SQLite stores ordered diagnostic timeline events', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 18, 10);
    database.saveSession(
      DiagnosticSessionRecord(
        id: 'timeline-session',
        startedAt: now,
        updatedAt: now,
        scenario: 'healthy',
        simulated: true,
        snapshotJson: '{}',
        dataHash: 'hash',
      ),
    );
    database.saveEvent(
      sessionId: 'timeline-session',
      occurredAt: now,
      type: 'session_started',
    );
    database.saveEvent(
      sessionId: 'timeline-session',
      occurredAt: now.add(const Duration(seconds: 1)),
      type: 'link_state_changed',
      payload: const {'state': 'online'},
    );

    final events = database.listEvents('timeline-session');
    expect(events.map((event) => event.type), [
      'session_started',
      'link_state_changed',
    ]);
    expect(events.last.payloadJson, contains('online'));
  });

  test('SQLite persists append-only contribution lifecycle history', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final profile = DeviceProfile.fromJson(
      jsonDecode(
            File(
              'device_profiles/batteries/_simulated/solardiag_sim.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>,
    );
    final lifecycle = ContributionLifecycle(
      contributionId: 'contribution-1',
      profile: profile,
      contributor: AuthenticatedActor.mock('author', ReviewRole.contributor),
      createdAt: DateTime.utc(2026),
      historyStore: database,
    );
    lifecycle.advance(
      to: ContributionStage.submitted,
      actor: AuthenticatedActor.mock('author', ReviewRole.contributor),
      at: DateTime.utc(2026, 1, 2),
    );

    final restored = ContributionLifecycle.restore(
      contributionId: 'contribution-1',
      profile: profile,
      historyStore: database,
    );
    expect(restored.stage, ContributionStage.submitted);
    expect(restored.records, hasLength(2));
    expect(restored.records.first.actorId, 'author');
  });

  test('SQLite audit_entries round-trips and is append-only', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 18, 12);

    // حفظ إدخال audit
    database.saveAuditEntry(
      sessionId: 'audit-session-1',
      sequence: 1,
      occurredAt: now,
      action: 'session_started',
      details: {'scenario': 'healthy'},
      previousHash: 'GENESIS',
      hash: 'hash-entry-1',
    );
    database.saveAuditEntry(
      sessionId: 'audit-session-1',
      sequence: 2,
      occurredAt: now.add(const Duration(seconds: 5)),
      action: 'parameter_changed',
      details: {'key': 'charge_limit', 'old': 55, 'new': 60},
      previousHash: 'hash-entry-1',
      hash: 'hash-entry-2',
    );

    // التحقق من تحميل الإدخالات مرتبةً
    final entries = database.loadAuditEntries('audit-session-1');
    expect(entries, hasLength(2));
    expect(entries.first['sequence'], 1);
    expect(entries.first['action'], 'session_started');
    expect(entries.last['sequence'], 2);
    expect(entries.last['previous_hash'], 'hash-entry-1');
  });

  test('SQLite audit_chain_heads round-trips head value', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);

    // لا توجد سجلات بعد
    expect(database.loadAuditHead('session-x'), isNull);

    // حفظ head
    database.saveAuditHead('session-x', 'hash-abc');
    expect(database.loadAuditHead('session-x'), 'hash-abc');

    // تحديث head
    database.saveAuditHead('session-x', 'hash-xyz');
    expect(database.loadAuditHead('session-x'), 'hash-xyz');
  });

  test('SQLite audit_entries append-only trigger rejects UPDATE', () {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 18, 12);

    database.saveAuditEntry(
      sessionId: 'session-y',
      sequence: 1,
      occurredAt: now,
      action: 'test_action',
      details: {},
      previousHash: 'GENESIS',
      hash: 'hash-1',
    );

    // محاولة تحديث يجب أن ترفعها trigger
    expect(
      () => database.rawExecuteForTest(
        "UPDATE audit_entries SET action = 'tampered' WHERE session_id = 'session-y'",
      ),
      throwsA(anything),
    );
  });
}
