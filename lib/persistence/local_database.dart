import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../parameters/parameter_backup.dart';

class DiagnosticSessionRecord {
  const DiagnosticSessionRecord({
    required this.id,
    required this.startedAt,
    required this.updatedAt,
    required this.scenario,
    required this.simulated,
    required this.snapshotJson,
    required this.dataHash,
  });

  final String id;
  final DateTime startedAt;
  final DateTime updatedAt;
  final String scenario;
  final bool simulated;
  final String snapshotJson;
  final String dataHash;
}

class LocalDatabase {
  LocalDatabase._(this._database) {
    _migrate();
  }

  final Database _database;

  factory LocalDatabase.inMemory() => LocalDatabase._(sqlite3.openInMemory());

  static Future<LocalDatabase> openDefault() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final path = [
      directory.path,
      'solardiag_pro.sqlite',
    ].join(Platform.pathSeparator);
    return LocalDatabase._(sqlite3.open(path));
  }

  void _migrate() {
    _database.execute('PRAGMA foreign_keys = ON');
    final version = _database.userVersion;
    if (version > 2) {
      throw StateError('Database schema is newer than this application.');
    }
    if (version == 0) {
      _database.execute('''
        CREATE TABLE diagnostic_sessions (
          id TEXT NOT NULL PRIMARY KEY,
          started_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          scenario TEXT NOT NULL,
          simulated INTEGER NOT NULL CHECK (simulated IN (0, 1)),
          snapshot_json TEXT NOT NULL,
          data_hash TEXT NOT NULL
        ) STRICT;
      ''');
      _database.execute('''
        CREATE TABLE parameter_backups (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          schema_version INTEGER NOT NULL,
          profile_id TEXT NOT NULL,
          device_identity TEXT NOT NULL,
          firmware TEXT NOT NULL,
          captured_at TEXT NOT NULL,
          values_json TEXT NOT NULL
        ) STRICT;
      ''');
      _database.execute('''
        CREATE INDEX parameter_backups_captured_at
        ON parameter_backups(captured_at DESC);
      ''');
      _database.userVersion = 1;
    }
    if (_database.userVersion < 2) {
      _database.execute('''
        CREATE TABLE app_settings (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL
        ) STRICT;
      ''');
      _database.userVersion = 2;
    }
  }

  void saveSession(DiagnosticSessionRecord record) {
    _database.execute(
      '''
      INSERT INTO diagnostic_sessions (
        id, started_at, updated_at, scenario, simulated, snapshot_json, data_hash
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        updated_at = excluded.updated_at,
        scenario = excluded.scenario,
        simulated = excluded.simulated,
        snapshot_json = excluded.snapshot_json,
        data_hash = excluded.data_hash
      ''',
      [
        record.id,
        record.startedAt.toUtc().toIso8601String(),
        record.updatedAt.toUtc().toIso8601String(),
        record.scenario,
        record.simulated ? 1 : 0,
        record.snapshotJson,
        record.dataHash,
      ],
    );
  }

  List<DiagnosticSessionRecord> listSessions() => [
    for (final row in _database.select(
      'SELECT * FROM diagnostic_sessions ORDER BY updated_at DESC',
    ))
      DiagnosticSessionRecord(
        id: row['id'] as String,
        startedAt: DateTime.parse(row['started_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        scenario: row['scenario'] as String,
        simulated: row['simulated'] == 1,
        snapshotJson: row['snapshot_json'] as String,
        dataHash: row['data_hash'] as String,
      ),
  ];

  void saveBackup(ParameterBackup backup) {
    _database.execute(
      '''
      INSERT INTO parameter_backups (
        schema_version, profile_id, device_identity, firmware,
        captured_at, values_json
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        backup.schemaVersion,
        backup.profileId,
        backup.deviceIdentity,
        backup.firmware,
        backup.capturedAt.toUtc().toIso8601String(),
        jsonEncode(backup.values),
      ],
    );
  }

  List<ParameterBackup> listBackups() => [
    for (final row in _database.select(
      'SELECT * FROM parameter_backups ORDER BY captured_at DESC, id DESC',
    ))
      ParameterBackup(
        schemaVersion: row['schema_version'] as int,
        profileId: row['profile_id'] as String,
        deviceIdentity: row['device_identity'] as String,
        firmware: row['firmware'] as String,
        capturedAt: DateTime.parse(row['captured_at'] as String),
        values: Map.unmodifiable(
          (jsonDecode(row['values_json'] as String) as Map<String, Object?>)
              .map((key, value) => MapEntry(key, value! as num)),
        ),
      ),
  ];

  bool getBool(String key, {bool defaultValue = false}) {
    final rows = _database.select(
      'SELECT value FROM app_settings WHERE key = ?',
      [key],
    );
    if (rows.isEmpty) return defaultValue;
    return rows.single['value'] == 'true';
  }

  void setBool(String key, bool value) {
    _database.execute(
      '''
      INSERT INTO app_settings (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      [key, value ? 'true' : 'false'],
    );
  }

  void close() => _database.close();
}
