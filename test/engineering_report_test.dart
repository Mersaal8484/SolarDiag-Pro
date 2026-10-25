import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/persistence/local_database.dart';
import 'package:solardiag_pro/reports/engineering_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DiagnosticSessionRecord record({
    bool simulated = true,
    String snapshot = '{"soc":{"value":78,"unit":"%","quality":"good"}}',
  }) => DiagnosticSessionRecord(
    id: simulated ? 'sim-1' : 'real-1',
    startedAt: DateTime.utc(2026, 10, 18, 8),
    updatedAt: DateTime.utc(2026, 10, 18, 9),
    scenario: 'healthy',
    simulated: simulated,
    snapshotJson: snapshot,
    dataHash: sha256.convert(utf8.encode(snapshot)).toString(),
  );

  EngineeringReportData data(List<DiagnosticSessionRecord> sessions) =>
      EngineeringReportData(
        sessions: sessions,
        parameters: const {'charge_limit': 55.2},
        alarms: const {},
        findings: const [
          {'severity': 'info', 'message': 'No active alarms reported'},
        ],
        technicianId: 'TECH-001',
      );

  test('JSON report includes watermark, readings, and session hash', () {
    final session = record();
    final report = const EngineeringReportService().buildJson(data([session]));
    expect(report['simulated'], isTrue);
    expect(report['watermark'], 'SIMULATED');
    expect(
      (report['sessions'] as List).single['sessionDataHash'],
      session.dataHash,
    );
    expect(report['parameterSnapshot'], {'charge_limit': 55.2});
  });

  test('report rejects mixed simulated and real sessions', () {
    expect(
      () => const EngineeringReportService().buildJson(
        data([record(), record(simulated: false)]),
      ),
      throwsStateError,
    );
  });

  test(
    'report rejects a session whose evidence no longer matches its hash',
    () {
      final valid = record();
      final tampered = DiagnosticSessionRecord(
        id: valid.id,
        startedAt: valid.startedAt,
        updatedAt: valid.updatedAt,
        scenario: valid.scenario,
        simulated: valid.simulated,
        snapshotJson: '{"soc":1}',
        dataHash: valid.dataHash,
      );
      expect(
        () => const EngineeringReportService().buildJson(data([tampered])),
        throwsStateError,
      );
    },
  );

  test(
    'PDF report contains simulated metadata and has a PDF signature',
    () async {
      final reportData = data([record()]);
      final report = const EngineeringReportService().buildJson(reportData);
      final bytes = await const EngineeringReportService().buildPdf(reportData);

      expect(report['watermark'], 'SIMULATED');
      expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );

  test('Arabic PDF is generated successfully for visual export', () async {
    final bytes = await const EngineeringReportService().buildPdf(
      data([record()]),
      language: ReportLanguage.arabic,
    );

    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('Arabic PDF extraction preserves logical label then value order', () async {
    final bytes = await const EngineeringReportService().buildPdf(
      data([record()]),
      language: ReportLanguage.arabic,
    );
    final extracted = _extractUncompressedPdfText(bytes);
    final section = extracted.indexOf('التعريف');
    final label = extracted.indexOf('الجهاز');
    final value = extracted.indexOf('SOLARDIAG-SIM-BMS');

    expect(section, greaterThanOrEqualTo(0), reason: extracted);
    expect(label, greaterThan(section), reason: extracted);
    expect(value, greaterThan(label), reason: extracted);
  });

  test('JSON report includes ALL sessions (multi-session)', () {
    final snapshot2 = '{"soc":{"value":65,"unit":"%","quality":"fair"}}';
    final session1 = record();
    final session2 = DiagnosticSessionRecord(
      id: 'sim-2',
      startedAt: DateTime.utc(2026, 10, 18, 10),
      updatedAt: DateTime.utc(2026, 10, 18, 11),
      scenario: 'gradualImbalance',
      simulated: true,
      snapshotJson: snapshot2,
      dataHash: sha256.convert(utf8.encode(snapshot2)).toString(),
    );
    final report = const EngineeringReportService().buildJson(
      data([session1, session2]),
    );
    final sessions = report['sessions'] as List;
    expect(sessions, hasLength(2));
    expect(sessions[0]['id'], 'sim-1');
    expect(sessions[1]['id'], 'sim-2');
    expect(sessions[1]['scenario'], 'gradualImbalance');
  });

  test(
    'report uses persisted events, samples, audit head, and diagnostics',
    () {
      final session = record();
      final reportData = EngineeringReportData(
        sessions: [session],
        parameters: const {'charge_limit': 55.2},
        eventsBySession: {
          session.id: [
            DiagnosticEventRecord(
              id: 1,
              sessionId: session.id,
              occurredAt: session.updatedAt,
              type: 'alarms_changed',
              payloadJson: '{"codes":["CELL_OVERVOLTAGE"]}',
            ),
          ],
        },
        samplesBySession: {
          session.id: [
            TelemetrySampleRecord(
              id: 1,
              sessionId: session.id,
              capturedAt: session.updatedAt,
              snapshotJson: session.snapshotJson,
              qualityFlagsJson: '{"soc":"good"}',
              previousHash: 'GENESIS',
              sampleHash: session.dataHash,
              isAggregate: false,
            ),
          ],
        },
        auditHeads: {session.id: 'audit-head-1'},
        findingsBySession: {
          session.id: const [
            {
              'code': 'CELL_DELTA',
              'severity': 'attention',
              'evidence': {'delta_v': 0.04},
            },
          ],
        },
      );

      final report = const EngineeringReportService().buildJson(reportData);
      final exportedSession = (report['sessions'] as List).single as Map;
      expect(exportedSession['auditChainHead'], 'audit-head-1');
      expect(exportedSession['alarmHistory'], ['CELL_OVERVOLTAGE']);
      expect(exportedSession['sampleSummary'], contains('sampleCount'));
      expect(exportedSession['findings'], isNotEmpty);
    },
  );

  test(
    'PDF report renders all sessions (multi-session) and has PDF signature',
    () async {
      final snapshot2 = '{"soc":{"value":65,"unit":"%","quality":"fair"}}';
      final session2 = DiagnosticSessionRecord(
        id: 'sim-2',
        startedAt: DateTime.utc(2026, 10, 18, 10),
        updatedAt: DateTime.utc(2026, 10, 18, 11),
        scenario: 'gradualImbalance',
        simulated: true,
        snapshotJson: snapshot2,
        dataHash: sha256.convert(utf8.encode(snapshot2)).toString(),
      );
      final reportData = data([record(), session2]);
      final report = const EngineeringReportService().buildJson(reportData);
      final exportedSessions = report['sessions'] as List;
      final bytes = await const EngineeringReportService().buildPdf(reportData);

      expect(
        exportedSessions.map((session) => (session as Map)['id']),
        orderedEquals(['sim-1', 'sim-2']),
      );
      expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    },
  );
}

String _extractUncompressedPdfText(List<int> bytes) {
  final source = latin1.decode(bytes, allowInvalid: true);
  final unicodeByCid = <int, String>{};

  for (final block in RegExp(
    r'beginbfchar(.*?)endbfchar',
    dotAll: true,
  ).allMatches(source)) {
    for (final mapping in RegExp(
      r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>',
    ).allMatches(block.group(1)!)) {
      unicodeByCid[int.parse(mapping.group(1)!, radix: 16)] =
          _decodeUtf16Hex(mapping.group(2)!);
    }
  }

  for (final block in RegExp(
    r'beginbfrange(.*?)endbfrange',
    dotAll: true,
  ).allMatches(source)) {
    for (final mapping in RegExp(
      r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>',
    ).allMatches(block.group(1)!)) {
      final first = int.parse(mapping.group(1)!, radix: 16);
      final last = int.parse(mapping.group(2)!, radix: 16);
      final destination = int.parse(mapping.group(3)!, radix: 16);
      for (var cid = first; cid <= last; cid++) {
        unicodeByCid[cid] = String.fromCharCode(destination + cid - first);
      }
    }
  }

  final output = StringBuffer();
  for (final operator in RegExp(
    r'(?:<([0-9A-Fa-f]+)>\s*Tj)|(?:\[(.*?)\]\s*TJ)',
    dotAll: true,
  ).allMatches(source)) {
    final chunks = <String>[
      if (operator.group(1) case final text?) text,
      if (operator.group(2) case final array?)
        for (final item in RegExp(
          r'<([0-9A-Fa-f]+)>',
        ).allMatches(array))
          item.group(1)!,
    ];
    for (final chunk in chunks) {
      for (var offset = 0; offset + 4 <= chunk.length; offset += 4) {
        final cid = int.parse(chunk.substring(offset, offset + 4), radix: 16);
        output.write(unicodeByCid[cid] ?? '');
      }
    }
    output.writeln();
  }
  return output.toString();
}

String _decodeUtf16Hex(String value) => String.fromCharCodes([
  for (var offset = 0; offset + 4 <= value.length; offset += 4)
    int.parse(value.substring(offset, offset + 4), radix: 16),
]);
