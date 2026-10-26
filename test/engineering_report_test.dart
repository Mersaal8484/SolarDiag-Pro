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
        gatewayVersion: null,
        deviceIdentity: 'SOLARDIAG-SIM-BMS',
        firmwareVersion: 'simulator-v2',
        profileVersion: 'solardiag.simulated.lfp16.v2',
        profileVerification: 'simulated',
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
    expect(
      (report['gateway'] as Map<String, Object?>)['version'],
      isNull,
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

  test(
    'Arabic PDF extraction preserves logical label then value order',
    () async {
      final bytes = await const EngineeringReportService().buildPdf(
        data([record()]),
        language: ReportLanguage.arabic,
      );
      final extracted = _normalizeExtractedArabic(
        _extractUncompressedPdfText(bytes),
      );
      final section = extracted.indexOf('التعريف');
      final label = extracted.indexOf('الجهاز');
      final value = extracted.indexOf('SOLARDIAG-SIM-BMS');

      expect(section, greaterThanOrEqualTo(0), reason: extracted);
      expect(label, greaterThan(section), reason: extracted);
      expect(value, greaterThan(label), reason: extracted);
    },
  );

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
        gatewayVersion: null,
        deviceIdentity: 'SOLARDIAG-SIM-BMS',
        firmwareVersion: 'simulator-v2',
        profileVersion: 'solardiag.simulated.lfp16.v2',
        profileVerification: 'simulated',
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
  final objects = <int, String>{
    for (final object in RegExp(
      r'(\d+)\s+\d+\s+obj(.*?)endobj',
      dotAll: true,
    ).allMatches(source))
      int.parse(object.group(1)!): object.group(2)!,
  };
  final fontObjectByResource = <String, int>{};
  for (final body in objects.values) {
    for (final reference in RegExp(
      r'/(F\d+)\s+(\d+)\s+\d+\s+R',
    ).allMatches(body)) {
      fontObjectByResource[reference.group(1)!] = int.parse(
        reference.group(2)!,
      );
    }
  }
  final unicodeByFont = <String, Map<int, String>>{};
  for (final entry in fontObjectByResource.entries) {
    final fontBody = objects[entry.value];
    if (fontBody == null) continue;
    final toUnicode = RegExp(
      r'/ToUnicode\s+(\d+)\s+\d+\s+R',
    ).firstMatch(fontBody);
    if (toUnicode == null) continue;
    final cmapBody = objects[int.parse(toUnicode.group(1)!)];
    if (cmapBody != null) {
      unicodeByFont[entry.key] = _parseToUnicodeCMap(cmapBody);
    }
  }

  final output = StringBuffer();
  Map<int, String> currentMap = const {};
  for (final operator in RegExp(
    r'/(F\d+)\s+[-+]?\d*\.?\d+\s+Tf|<([0-9A-Fa-f]+)>\s*Tj|\[(.*?)\]\s*TJ',
    dotAll: true,
  ).allMatches(source)) {
    final fontResource = operator.group(1);
    if (fontResource != null) {
      currentMap = unicodeByFont[fontResource] ?? const {};
      continue;
    }
    final chunks = <String>[
      ?operator.group(2),
      if (operator.group(3) case final array?)
        for (final item in RegExp(r'<([0-9A-Fa-f]+)>').allMatches(array))
          item.group(1)!,
    ];
    for (final chunk in chunks) {
      for (var offset = 0; offset + 4 <= chunk.length; offset += 4) {
        final cid = int.parse(chunk.substring(offset, offset + 4), radix: 16);
        output.write(currentMap[cid] ?? '');
      }
    }
    output.writeln();
  }
  return output.toString();
}

Map<int, String> _parseToUnicodeCMap(String source) {
  final result = <int, String>{};
  for (final block in RegExp(
    r'beginbfchar(.*?)endbfchar',
    dotAll: true,
  ).allMatches(source)) {
    for (final mapping in RegExp(
      r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>',
    ).allMatches(block.group(1)!)) {
      result[int.parse(mapping.group(1)!, radix: 16)] = _decodeUtf16Hex(
        mapping.group(2)!,
      );
    }
  }
  for (final block in RegExp(
    r'beginbfrange(.*?)endbfrange',
    dotAll: true,
  ).allMatches(source)) {
    final contents = block.group(1)!;
    for (final mapping in RegExp(
      r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>',
    ).allMatches(contents)) {
      final first = int.parse(mapping.group(1)!, radix: 16);
      final last = int.parse(mapping.group(2)!, radix: 16);
      final destination = int.parse(mapping.group(3)!, radix: 16);
      for (var cid = first; cid <= last; cid++) {
        result[cid] = String.fromCharCode(destination + cid - first);
      }
    }
    for (final mapping in RegExp(
      r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*\[(.*?)\]',
      dotAll: true,
    ).allMatches(contents)) {
      final first = int.parse(mapping.group(1)!, radix: 16);
      final last = int.parse(mapping.group(2)!, radix: 16);
      final destinations = RegExp(
        r'<([0-9A-Fa-f]+)>',
      ).allMatches(mapping.group(3)!).toList();
      for (
        var cid = first;
        cid <= last && cid - first < destinations.length;
        cid++
      ) {
        result[cid] = _decodeUtf16Hex(destinations[cid - first].group(1)!);
      }
    }
  }
  return result;
}

String _decodeUtf16Hex(String value) => String.fromCharCodes([
  for (var offset = 0; offset + 4 <= value.length; offset += 4)
    int.parse(value.substring(offset, offset + 4), radix: 16),
]);

String _normalizeExtractedArabic(String source) => source
    .split('\n')
    .map((line) {
      final hasPresentationForms = line.runes.any(
        (codePoint) => codePoint >= 0xFE70 && codePoint <= 0xFEFF,
      );
      if (!hasPresentationForms) return line;
      final normalized = line.runes
          .map((codePoint) => _arabicPresentationForms[codePoint] ?? '')
          .join();
      return String.fromCharCodes(normalized.runes.toList().reversed);
    })
    .join('\n');

const _arabicPresentationForms = <int, String>{
  0xFE80: 'ء',
  0xFE81: 'آ',
  0xFE82: 'آ',
  0xFE83: 'أ',
  0xFE84: 'أ',
  0xFE85: 'ؤ',
  0xFE86: 'ؤ',
  0xFE87: 'إ',
  0xFE88: 'إ',
  0xFE89: 'ئ',
  0xFE8A: 'ئ',
  0xFE8B: 'ئ',
  0xFE8C: 'ئ',
  0xFE8D: 'ا',
  0xFE8E: 'ا',
  0xFE8F: 'ب',
  0xFE90: 'ب',
  0xFE91: 'ب',
  0xFE92: 'ب',
  0xFE93: 'ة',
  0xFE94: 'ة',
  0xFE95: 'ت',
  0xFE96: 'ت',
  0xFE97: 'ت',
  0xFE98: 'ت',
  0xFE99: 'ث',
  0xFE9A: 'ث',
  0xFE9B: 'ث',
  0xFE9C: 'ث',
  0xFE9D: 'ج',
  0xFE9E: 'ج',
  0xFE9F: 'ج',
  0xFEA0: 'ج',
  0xFEA1: 'ح',
  0xFEA2: 'ح',
  0xFEA3: 'ح',
  0xFEA4: 'ح',
  0xFEA5: 'خ',
  0xFEA6: 'خ',
  0xFEA7: 'خ',
  0xFEA8: 'خ',
  0xFEA9: 'د',
  0xFEAA: 'د',
  0xFEAB: 'ذ',
  0xFEAC: 'ذ',
  0xFEAD: 'ر',
  0xFEAE: 'ر',
  0xFEAF: 'ز',
  0xFEB0: 'ز',
  0xFEB1: 'س',
  0xFEB2: 'س',
  0xFEB3: 'س',
  0xFEB4: 'س',
  0xFEB5: 'ش',
  0xFEB6: 'ش',
  0xFEB7: 'ش',
  0xFEB8: 'ش',
  0xFEB9: 'ص',
  0xFEBA: 'ص',
  0xFEBB: 'ص',
  0xFEBC: 'ص',
  0xFEBD: 'ض',
  0xFEBE: 'ض',
  0xFEBF: 'ض',
  0xFEC0: 'ض',
  0xFEC1: 'ط',
  0xFEC2: 'ط',
  0xFEC3: 'ط',
  0xFEC4: 'ط',
  0xFEC5: 'ظ',
  0xFEC6: 'ظ',
  0xFEC7: 'ظ',
  0xFEC8: 'ظ',
  0xFEC9: 'ع',
  0xFECA: 'ع',
  0xFECB: 'ع',
  0xFECC: 'ع',
  0xFECD: 'غ',
  0xFECE: 'غ',
  0xFECF: 'غ',
  0xFED0: 'غ',
  0xFED1: 'ف',
  0xFED2: 'ف',
  0xFED3: 'ف',
  0xFED4: 'ف',
  0xFED5: 'ق',
  0xFED6: 'ق',
  0xFED7: 'ق',
  0xFED8: 'ق',
  0xFED9: 'ك',
  0xFEDA: 'ك',
  0xFEDB: 'ك',
  0xFEDC: 'ك',
  0xFEDD: 'ل',
  0xFEDE: 'ل',
  0xFEDF: 'ل',
  0xFEE0: 'ل',
  0xFEE1: 'م',
  0xFEE2: 'م',
  0xFEE3: 'م',
  0xFEE4: 'م',
  0xFEE5: 'ن',
  0xFEE6: 'ن',
  0xFEE7: 'ن',
  0xFEE8: 'ن',
  0xFEE9: 'ه',
  0xFEEA: 'ه',
  0xFEEB: 'ه',
  0xFEEC: 'ه',
  0xFEED: 'و',
  0xFEEE: 'و',
  0xFEEF: 'ى',
  0xFEF0: 'ى',
  0xFEF1: 'ي',
  0xFEF2: 'ي',
  0xFEF3: 'ي',
  0xFEF4: 'ي',
  0xFEF5: 'آل',
  0xFEF6: 'آل',
  0xFEF7: 'أل',
  0xFEF8: 'أل',
  0xFEF9: 'إل',
  0xFEFA: 'إل',
  0xFEFB: 'ال',
  0xFEFC: 'ال',
};
