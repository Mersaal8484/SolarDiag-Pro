import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../audit/audit_chain.dart';
import '../contribution/lifecycle.dart';
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

class DiagnosticEventRecord {
  const DiagnosticEventRecord({
    required this.id,
    required this.sessionId,
    required this.occurredAt,
    required this.type,
    required this.payloadJson,
  });

  final int id;
  final String sessionId;
  final DateTime occurredAt;
  final String type;
  final String payloadJson;
}

class TelemetrySampleRecord {
  const TelemetrySampleRecord({
    required this.id,
    required this.sessionId,
    required this.capturedAt,
    required this.snapshotJson,
    required this.qualityFlagsJson,
    required this.previousHash,
    required this.sampleHash,
    required this.isAggregate,
    this.aggregateJson,
  });

  final int id;
  final String sessionId;
  final DateTime capturedAt;
  final String snapshotJson;
  final String qualityFlagsJson;
  final String previousHash;
  final String sampleHash;
  final bool isAggregate;
  final String? aggregateJson;
}

class TelemetryRetentionPolicy {
  const TelemetryRetentionPolicy({
    this.fullResolutionWindow = const Duration(minutes: 10),
    this.downsampleBucket = const Duration(minutes: 5),
    this.maximumAge = const Duration(days: 30),
  });

  final Duration fullResolutionWindow;
  final Duration downsampleBucket;
  final Duration maximumAge;
}

class LocalDatabase implements LifecycleHistoryStore {
  LocalDatabase._(
    this._database, {
    this.telemetryRetentionPolicy = const TelemetryRetentionPolicy(),
  }) {
    _migrate();
  }

  final Database _database;
  final TelemetryRetentionPolicy telemetryRetentionPolicy;

  factory LocalDatabase.inMemory({
    TelemetryRetentionPolicy telemetryRetentionPolicy =
        const TelemetryRetentionPolicy(),
  }) => LocalDatabase._(
    sqlite3.openInMemory(),
    telemetryRetentionPolicy: telemetryRetentionPolicy,
  );

  factory LocalDatabase.openForTest(
    String path, {
    TelemetryRetentionPolicy telemetryRetentionPolicy =
        const TelemetryRetentionPolicy(),
  }) => LocalDatabase._(
    sqlite3.open(path),
    telemetryRetentionPolicy: telemetryRetentionPolicy,
  );

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
    if (version > 7) {
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
    if (_database.userVersion < 3) {
      _database.execute('''
        CREATE TABLE diagnostic_events (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          occurred_at TEXT NOT NULL,
          type TEXT NOT NULL,
          payload_json TEXT NOT NULL,
          FOREIGN KEY (session_id) REFERENCES diagnostic_sessions(id)
            ON DELETE CASCADE
        ) STRICT;
      ''');
      _database.execute('''
        CREATE INDEX diagnostic_events_session_time
        ON diagnostic_events(session_id, occurred_at ASC, id ASC);
      ''');
      _database.userVersion = 3;
    }
    if (_database.userVersion < 4) {
      _database.execute('''
        CREATE TABLE contribution_lifecycle_history (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          contribution_id TEXT NOT NULL,
          stage TEXT NOT NULL,
          actor_id TEXT NOT NULL,
          role TEXT NOT NULL,
          occurred_at TEXT NOT NULL,
          reason TEXT
        ) STRICT;
      ''');
      _database.execute('''
        CREATE INDEX contribution_lifecycle_order
        ON contribution_lifecycle_history(contribution_id, id ASC);
      ''');
      _database.execute('''
        CREATE TRIGGER contribution_lifecycle_no_update
        BEFORE UPDATE ON contribution_lifecycle_history
        BEGIN SELECT RAISE(ABORT, 'lifecycle history is append-only'); END;
      ''');
      _database.execute('''
        CREATE TRIGGER contribution_lifecycle_no_delete
        BEFORE DELETE ON contribution_lifecycle_history
        BEGIN SELECT RAISE(ABORT, 'lifecycle history is append-only'); END;
      ''');
      _database.userVersion = 4;
    }
    if (_database.userVersion < 5) {
      _database.execute('''
        CREATE TABLE research_sessions (
          id TEXT NOT NULL PRIMARY KEY,
          document_json TEXT NOT NULL
        ) STRICT;
      ''');
      _database.execute('''
        CREATE TABLE research_findings (
          id TEXT NOT NULL PRIMARY KEY,
          document_json TEXT NOT NULL
        ) STRICT;
      ''');
      _database.userVersion = 5;
    }
    if (_database.userVersion < 6) {
      // Migration 6: AuditChain persistence.
      // يُخزَّن كل إدخال audit مع sequence وhash السابق لضمان سلامة السلسلة.
      // الجدول للإلحاق فقط (لا تحديث، لا حذف) لمنع التلاعب.
      _database.execute('''
        CREATE TABLE audit_entries (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          sequence INTEGER NOT NULL,
          occurred_at TEXT NOT NULL,
          action TEXT NOT NULL,
          details_json TEXT NOT NULL,
          previous_hash TEXT NOT NULL,
          hash TEXT NOT NULL
        ) STRICT;
      ''');
      _database.execute('''
        CREATE INDEX audit_entries_session_seq
        ON audit_entries(session_id, sequence ASC);
      ''');
      _database.execute('''
        CREATE TRIGGER audit_entries_no_update
        BEFORE UPDATE ON audit_entries
        BEGIN SELECT RAISE(ABORT, 'audit entries are append-only'); END;
      ''');
      _database.execute('''
        CREATE TRIGGER audit_entries_no_delete
        BEFORE DELETE ON audit_entries
        BEGIN SELECT RAISE(ABORT, 'audit entries are append-only'); END;
      ''');
      // جدول head منفصل لتخزين hash الرأس الحالي لكل جلسة audit.
      _database.execute('''
        CREATE TABLE audit_chain_heads (
          session_id TEXT NOT NULL PRIMARY KEY,
          head TEXT NOT NULL
        ) STRICT;
      ''');
      _database.userVersion = 6;
    }
    if (_database.userVersion < 7) {
      _database.execute('''
        CREATE TABLE telemetry_samples (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          captured_at TEXT NOT NULL,
          snapshot_json TEXT NOT NULL,
          quality_flags_json TEXT NOT NULL,
          aggregate_json TEXT,
          is_aggregate INTEGER NOT NULL CHECK (is_aggregate IN (0, 1)),
          previous_hash TEXT NOT NULL,
          sample_hash TEXT NOT NULL,
          FOREIGN KEY (session_id) REFERENCES diagnostic_sessions(id)
            ON DELETE CASCADE
        ) STRICT;
      ''');
      _database.execute('''
        CREATE INDEX telemetry_samples_session_time
        ON telemetry_samples(session_id, captured_at ASC, id ASC);
      ''');
      _database.userVersion = 7;
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

  void saveTelemetrySample({
    required String sessionId,
    required DateTime capturedAt,
    required String snapshotJson,
    Map<String, Object?> qualityFlags = const {},
  }) {
    final sessionExists = _database.select(
      'SELECT 1 FROM diagnostic_sessions WHERE id = ?',
      [sessionId],
    );
    if (sessionExists.isEmpty) {
      throw StateError('Telemetry requires an existing diagnostic session.');
    }
    final timestamp = capturedAt.toUtc().toIso8601String();
    final qualityJson = jsonEncode(qualityFlags);
    final previous = _latestSampleHash(sessionId) ?? 'GENESIS';
    final hash = _telemetryHash(
      sessionId: sessionId,
      capturedAt: timestamp,
      snapshotJson: snapshotJson,
      qualityFlagsJson: qualityJson,
      aggregateJson: null,
      isAggregate: false,
      previousHash: previous,
    );
    _database.execute(
      '''
      INSERT INTO telemetry_samples (
        session_id, captured_at, snapshot_json, quality_flags_json,
        aggregate_json, is_aggregate, previous_hash, sample_hash
      ) VALUES (?, ?, ?, ?, NULL, 0, ?, ?)
      ''',
      [sessionId, timestamp, snapshotJson, qualityJson, previous, hash],
    );
    _applyTelemetryRetention(sessionId, capturedAt.toUtc());
    _rehashTelemetry(sessionId);
  }

  List<TelemetrySampleRecord> listTelemetrySamples(String sessionId) => [
    for (final row in _database.select(
      '''
      SELECT * FROM telemetry_samples
      WHERE session_id = ?
      ORDER BY captured_at ASC, id ASC
      ''',
      [sessionId],
    ))
      _telemetryRecord(row),
  ];

  bool verifyTelemetryChain(String sessionId) {
    var previous = 'GENESIS';
    for (final sample in listTelemetrySamples(sessionId)) {
      if (sample.previousHash != previous) return false;
      final expected = _telemetryHash(
        sessionId: sample.sessionId,
        capturedAt: sample.capturedAt.toUtc().toIso8601String(),
        snapshotJson: sample.snapshotJson,
        qualityFlagsJson: sample.qualityFlagsJson,
        aggregateJson: sample.aggregateJson,
        isAggregate: sample.isAggregate,
        previousHash: previous,
      );
      if (sample.sampleHash != expected) return false;
      previous = sample.sampleHash;
    }
    final sessions = _database.select(
      'SELECT data_hash FROM diagnostic_sessions WHERE id = ?',
      [sessionId],
    );
    return sessions.isNotEmpty && sessions.single['data_hash'] == previous;
  }

  void _applyTelemetryRetention(String sessionId, DateTime referenceTime) {
    final oldestAllowed = referenceTime.subtract(
      telemetryRetentionPolicy.maximumAge,
    );
    _database.execute(
      'DELETE FROM telemetry_samples WHERE session_id = ? AND captured_at < ?',
      [sessionId, oldestAllowed.toIso8601String()],
    );

    final fullResolutionCutoff = referenceTime.subtract(
      telemetryRetentionPolicy.fullResolutionWindow,
    );
    final oldRows = _database.select(
      '''
      SELECT * FROM telemetry_samples
      WHERE session_id = ? AND captured_at < ? AND is_aggregate = 0
      ORDER BY captured_at ASC, id ASC
      ''',
      [sessionId, fullResolutionCutoff.toIso8601String()],
    );
    final bucketMillis =
        telemetryRetentionPolicy.downsampleBucket.inMilliseconds;
    if (bucketMillis <= 0) return;
    final buckets = <int, List<Row>>{};
    for (final row in oldRows) {
      final time = DateTime.parse(row['captured_at'] as String).toUtc();
      final key = time.millisecondsSinceEpoch ~/ bucketMillis;
      buckets.putIfAbsent(key, () => []).add(row);
    }
    for (final entry in buckets.entries) {
      if (entry.value.length < 2) continue;
      final rows = entry.value;
      final latest = rows.last;
      final aggregate = _aggregateSnapshots(rows);
      final bucketTime = DateTime.fromMillisecondsSinceEpoch(
        entry.key * bucketMillis,
        isUtc: true,
      ).toIso8601String();
      final ids = rows.map((row) => row['id'] as int).toList();
      final placeholders = List.filled(ids.length, '?').join(',');
      _database.execute(
        'DELETE FROM telemetry_samples WHERE id IN ($placeholders)',
        ids,
      );
      _database.execute(
        '''
        INSERT INTO telemetry_samples (
          session_id, captured_at, snapshot_json, quality_flags_json,
          aggregate_json, is_aggregate, previous_hash, sample_hash
        ) VALUES (?, ?, ?, ?, ?, 1, '', '')
        ''',
        [
          sessionId,
          bucketTime,
          latest['snapshot_json'] as String,
          jsonEncode({'downsampled': true, 'sampleCount': rows.length}),
          jsonEncode(aggregate),
        ],
      );
    }
  }

  Map<String, Object?> _aggregateSnapshots(List<Row> rows) {
    final values = <String, List<num>>{};
    for (final row in rows) {
      final decoded = jsonDecode(row['snapshot_json'] as String);
      if (decoded is Map<String, Object?>) {
        _collectNumericValues(decoded, '', values);
      }
    }
    return {
      'sampleCount': rows.length,
      'series': {
        for (final entry in values.entries)
          entry.key: {
            'min': entry.value.reduce((a, b) => a < b ? a : b),
            'max': entry.value.reduce((a, b) => a > b ? a : b),
            'mean':
                entry.value.fold<double>(0, (sum, value) => sum + value) /
                entry.value.length,
          },
      },
    };
  }

  static void _collectNumericValues(
    Object? value,
    String path,
    Map<String, List<num>> output,
  ) {
    if (value is num) {
      output.putIfAbsent(path, () => []).add(value);
      return;
    }
    if (value is Map<String, Object?>) {
      for (final entry in value.entries) {
        final child = path.isEmpty ? entry.key : '$path.${entry.key}';
        _collectNumericValues(entry.value, child, output);
      }
      return;
    }
    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        _collectNumericValues(value[index], '$path[$index]', output);
      }
    }
  }

  void _rehashTelemetry(String sessionId) {
    var previous = 'GENESIS';
    final rows = _database.select(
      '''
      SELECT * FROM telemetry_samples
      WHERE session_id = ? ORDER BY captured_at ASC, id ASC
      ''',
      [sessionId],
    );
    for (final row in rows) {
      final hash = _telemetryHash(
        sessionId: sessionId,
        capturedAt: row['captured_at'] as String,
        snapshotJson: row['snapshot_json'] as String,
        qualityFlagsJson: row['quality_flags_json'] as String,
        aggregateJson: row['aggregate_json'] as String?,
        isAggregate: row['is_aggregate'] == 1,
        previousHash: previous,
      );
      _database.execute(
        '''
        UPDATE telemetry_samples
        SET previous_hash = ?, sample_hash = ? WHERE id = ?
        ''',
        [previous, hash, row['id']],
      );
      previous = hash;
    }
    _database.execute(
      'UPDATE diagnostic_sessions SET data_hash = ? WHERE id = ?',
      [previous, sessionId],
    );
  }

  String? _latestSampleHash(String sessionId) {
    final rows = _database.select(
      '''
      SELECT sample_hash FROM telemetry_samples
      WHERE session_id = ? ORDER BY captured_at DESC, id DESC LIMIT 1
      ''',
      [sessionId],
    );
    return rows.isEmpty ? null : rows.single['sample_hash'] as String;
  }

  static String _telemetryHash({
    required String sessionId,
    required String capturedAt,
    required String snapshotJson,
    required String qualityFlagsJson,
    required String? aggregateJson,
    required bool isAggregate,
    required String previousHash,
  }) => sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'sessionId': sessionId,
            'capturedAt': capturedAt,
            'snapshot': snapshotJson,
            'qualityFlags': qualityFlagsJson,
            'aggregate': aggregateJson,
            'isAggregate': isAggregate,
            'previousHash': previousHash,
          }),
        ),
      )
      .toString();

  static TelemetrySampleRecord _telemetryRecord(Row row) =>
      TelemetrySampleRecord(
        id: row['id'] as int,
        sessionId: row['session_id'] as String,
        capturedAt: DateTime.parse(row['captured_at'] as String),
        snapshotJson: row['snapshot_json'] as String,
        qualityFlagsJson: row['quality_flags_json'] as String,
        aggregateJson: row['aggregate_json'] as String?,
        isAggregate: row['is_aggregate'] == 1,
        previousHash: row['previous_hash'] as String,
        sampleHash: row['sample_hash'] as String,
      );

  void saveEvent({
    required String sessionId,
    required DateTime occurredAt,
    required String type,
    Map<String, Object?> payload = const {},
  }) {
    _database.execute(
      '''
      INSERT INTO diagnostic_events (
        session_id, occurred_at, type, payload_json
      ) VALUES (?, ?, ?, ?)
      ''',
      [
        sessionId,
        occurredAt.toUtc().toIso8601String(),
        type,
        jsonEncode(payload),
      ],
    );
  }

  List<DiagnosticEventRecord> listEvents(String sessionId) => [
    for (final row in _database.select(
      '''
      SELECT * FROM diagnostic_events
      WHERE session_id = ?
      ORDER BY occurred_at ASC, id ASC
      ''',
      [sessionId],
    ))
      DiagnosticEventRecord(
        id: row['id'] as int,
        sessionId: row['session_id'] as String,
        occurredAt: DateTime.parse(row['occurred_at'] as String),
        type: row['type'] as String,
        payloadJson: row['payload_json'] as String,
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

  String? getSetting(String key) {
    final rows = _database.select(
      'SELECT value FROM app_settings WHERE key = ?',
      [key],
    );
    return rows.isEmpty ? null : rows.single['value'] as String;
  }

  void setSetting(String key, String value) {
    _database.execute(
      '''
      INSERT INTO app_settings (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      [key, value],
    );
  }

  void saveResearchSessionDocument(String id, String documentJson) {
    _saveResearchDocument('research_sessions', id, documentJson);
  }

  String? researchSessionDocument(String id) =>
      _researchDocument('research_sessions', id);

  void saveResearchFindingDocument(String id, String documentJson) {
    _saveResearchDocument('research_findings', id, documentJson);
  }

  List<String> researchFindingDocuments() => [
    for (final row in _database.select(
      'SELECT document_json FROM research_findings ORDER BY id ASC',
    ))
      row['document_json'] as String,
  ];

  void _saveResearchDocument(String table, String id, String documentJson) {
    if (table != 'research_sessions' && table != 'research_findings') {
      throw ArgumentError.value(table, 'table');
    }
    _database.execute(
      '''
      INSERT INTO $table (id, document_json) VALUES (?, ?)
      ON CONFLICT(id) DO UPDATE SET document_json = excluded.document_json
      ''',
      [id, documentJson],
    );
  }

  String? _researchDocument(String table, String id) {
    if (table != 'research_sessions' && table != 'research_findings') {
      throw ArgumentError.value(table, 'table');
    }
    final rows = _database.select(
      'SELECT document_json FROM $table WHERE id = ?',
      [id],
    );
    return rows.isEmpty ? null : rows.single['document_json'] as String;
  }

  @override
  void appendLifecycleRecord(String contributionId, ReviewRecord record) {
    _database.execute(
      '''
      INSERT INTO contribution_lifecycle_history (
        contribution_id, stage, actor_id, role, occurred_at, reason
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        contributionId,
        record.stage.name,
        record.actorId,
        record.role.name,
        record.at.toUtc().toIso8601String(),
        record.reason,
      ],
    );
  }

  @override
  List<ReviewRecord> loadLifecycleRecords(String contributionId) => [
    for (final row in _database.select(
      '''
      SELECT stage, actor_id, role, occurred_at, reason
      FROM contribution_lifecycle_history
      WHERE contribution_id = ?
      ORDER BY id ASC
      ''',
      [contributionId],
    ))
      ReviewRecord(
        stage: ContributionStage.values.byName(row['stage'] as String),
        actorId: row['actor_id'] as String,
        role: ReviewRole.values.byName(row['role'] as String),
        at: DateTime.parse(row['occurred_at'] as String),
        reason: row['reason'] as String?,
      ),
  ];

  // ─── AuditChain persistence ───────────────────────────────────────────────

  /// يُخزِّن إدخال audit مرتبطاً بـ [sessionId].
  /// الجدول للإلحاق فقط؛ يرفع SQLite trigger عند محاولة التحديث أو الحذف.
  void saveAuditEntry({
    required String sessionId,
    required int sequence,
    required DateTime occurredAt,
    required String action,
    required Map<String, Object?> details,
    required String previousHash,
    required String hash,
  }) {
    _database.execute(
      '''
      INSERT INTO audit_entries (
        session_id, sequence, occurred_at, action,
        details_json, previous_hash, hash
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        sessionId,
        sequence,
        occurredAt.toUtc().toIso8601String(),
        action,
        jsonEncode(details),
        previousHash,
        hash,
      ],
    );
  }

  /// يُحدِّث hash الرأس لسلسلة audit الخاصة بـ [sessionId].
  void saveAuditHead(String sessionId, String head) {
    _database.execute(
      '''
      INSERT INTO audit_chain_heads (session_id, head) VALUES (?, ?)
      ON CONFLICT(session_id) DO UPDATE SET head = excluded.head
      ''',
      [sessionId, head],
    );
  }

  /// يُحمِّل جميع إدخالات audit الخاصة بـ [sessionId] مرتبةً حسب sequence.
  List<Map<String, Object?>> loadAuditEntries(String sessionId) => [
    for (final row in _database.select(
      '''
      SELECT sequence, occurred_at, action, details_json, previous_hash, hash
      FROM audit_entries
      WHERE session_id = ?
      ORDER BY sequence ASC
      ''',
      [sessionId],
    ))
      {
        'sequence': row['sequence'] as int,
        'timestamp': row['occurred_at'] as String,
        'action': row['action'] as String,
        'details': jsonDecode(row['details_json'] as String),
        'previous_hash': row['previous_hash'] as String,
        'hash': row['hash'] as String,
      },
  ];

  /// يُرجع hash الرأس المخزَّن لـ [sessionId]، أو null إذا لم تُوجَد سجلات.
  String? loadAuditHead(String sessionId) {
    final rows = _database.select(
      'SELECT head FROM audit_chain_heads WHERE session_id = ?',
      [sessionId],
    );
    return rows.isEmpty ? null : rows.single['head'] as String;
  }

  void close() => _database.close();

  int get schemaVersionForTest => _database.userVersion;

  /// للاختبار فقط: تنفيذ SQL خام للتحقق من صحة triggers.
  // ignore: avoid_returning_null_for_void
  void rawExecuteForTest(String sql) => _database.execute(sql);
}

/// منفذ استمرارية لـ [AuditChainStore] يعتمد على قاعدة بيانات SQLite المحلية [LocalDatabase].
/// يربط سجلات التدقيق بمعرف الجلسة [sessionId] ويضمن أن تكون السجلات غير قابلة للتعديل.
class DatabaseAuditChainStore implements AuditChainStore {
  const DatabaseAuditChainStore({
    required this.database,
    required this.sessionId,
  });

  final LocalDatabase database;
  final String sessionId;

  @override
  StoredAuditChain? load() {
    final entriesData = database.loadAuditEntries(sessionId);
    final head = database.loadAuditHead(sessionId);
    if (entriesData.isEmpty && head == null) return null;
    final entries = [for (final map in entriesData) AuditEntry.fromJson(map)];
    return StoredAuditChain(entries: entries, head: head ?? 'GENESIS');
  }

  @override
  void saveEntries(List<AuditEntry> entries) {
    for (final entry in entries) {
      try {
        database.saveAuditEntry(
          sessionId: sessionId,
          sequence: entry.sequence,
          occurredAt: entry.timestamp,
          action: entry.action,
          details: entry.details,
          previousHash: entry.previousHash,
          hash: entry.hash,
        );
      } catch (_) {
        // Ignored if already inserted (append-only trigger)
      }
    }
  }

  @override
  void saveHead(String head) {
    database.saveAuditHead(sessionId, head);
  }

  @override
  void saveHeadMac(String head, String mac) {
    // Session SQLite tables can persist head; MAC storage can be added to audit_chain_heads
  }
}
