import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../design/accessibility.dart';
import '../persistence/local_database.dart';

enum ReportLanguage { english, arabic, bilingual }

class ReportExportResult {
  const ReportExportResult({required this.jsonPath, required this.pdfPath});

  final String jsonPath;
  final String pdfPath;
}

class EngineeringReportData {
  const EngineeringReportData({
    required this.sessions,
    required this.parameters,
    this.eventsBySession = const {},
    this.samplesBySession = const {},
    this.auditHeads = const {},
    this.findingsBySession = const {},
    this.alarms = const {},
    this.findings = const [],
    this.technicianId,
    this.gatewayVersion = 'SolarDiag virtual gateway v2',
    this.deviceIdentity = 'SOLARDIAG-SIM-BMS',
    this.firmwareVersion = 'simulator-v2',
    this.profileVersion = 'solardiag.simulated.lfp16.v2',
    this.profileVerification = 'simulated',
    this.digitPreference = DigitPreference.western,
  });

  final List<DiagnosticSessionRecord> sessions;
  final Map<String, num> parameters;
  final Map<String, List<DiagnosticEventRecord>> eventsBySession;
  final Map<String, List<TelemetrySampleRecord>> samplesBySession;
  final Map<String, String> auditHeads;
  final Map<String, List<Map<String, Object?>>> findingsBySession;
  final Set<String> alarms;
  final List<Map<String, String>> findings;
  final String? technicianId;
  final String gatewayVersion;
  final String deviceIdentity;
  final String firmwareVersion;
  final String profileVersion;
  final String profileVerification;
  final DigitPreference digitPreference;
}

class EngineeringReportService {
  const EngineeringReportService();

  Map<String, Object?> buildJson(EngineeringReportData data) {
    _validate(data);
    final simulated = data.sessions.first.simulated;
    return {
      'schemaVersion': 1,
      'reportType': 'SolarDiag Pro engineering report',
      'simulated': simulated,
      'watermark': simulated ? 'SIMULATED' : null,
      'device': {
        'identity': data.deviceIdentity,
        'firmware': data.firmwareVersion,
      },
      'gateway': {'version': data.gatewayVersion},
      'profile': {
        'version': data.profileVersion,
        'verification': data.profileVerification,
      },
      'technicianId': data.technicianId,
      'sessions': [
        for (final session in data.sessions)
          {
            'id': session.id,
            'startedAt': session.startedAt.toUtc().toIso8601String(),
            'updatedAt': session.updatedAt.toUtc().toIso8601String(),
            'scenario': session.scenario,
            'simulated': session.simulated,
            'sessionDataHash': session.dataHash,
            'auditChainHead': data.auditHeads[session.id] ?? 'GENESIS',
            'readings': jsonDecode(session.snapshotJson),
            'alarmHistory': _alarmHistory(
              data.eventsBySession[session.id] ?? const [],
            ).toList()..sort(),
            'sampleSummary': _sampleSummary(
              data.samplesBySession[session.id] ?? const [],
            ),
            'findings': data.findingsBySession[session.id] ?? const [],
          },
      ],
      'parameterSnapshot': data.parameters,
    };
  }

  String encodeJson(EngineeringReportData data) =>
      const JsonEncoder.withIndent('  ').convert(buildJson(data));

  Future<Uint8List> buildPdf(
    EngineeringReportData data, {
    ReportLanguage language = ReportLanguage.bilingual,
  }) async {
    final report = buildJson(data);
    final simulated = report['simulated']! as bool;
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-SemiBold.ttf'),
    );
    final document = pw.Document(
      compress: false,
      title: 'SolarDiag Pro Engineering Report',
      author: 'SolarDiag Pro',
      subject: simulated
          ? 'SIMULATED diagnostic engineering report'
          : 'Diagnostic engineering report',
      keywords: simulated
          ? 'SolarDiag,engineering,SIMULATED'
          : 'SolarDiag,engineering',
    );
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          textDirection: language == ReportLanguage.arabic
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
          buildBackground: simulated
              ? (context) => pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Center(
                    child: pw.Transform.rotate(
                      angle: -0.18,
                      child: pw.Text(
                        'SIMULATED · محاكاة',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 58,
                          color: PdfColors.grey300,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        header: (context) => pw.Text(
          _label(
            'SolarDiag Pro engineering report',
            'تقرير SolarDiag Pro الهندسي',
            language,
          ),
          style: pw.TextStyle(font: bold, fontSize: 15),
        ),
        footer: (context) => pw.Text(
          '${context.pageNumber} / ${context.pagesCount} · ${data.sessions.first.dataHash}',
          style: const pw.TextStyle(fontSize: 7),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          _section(
            _label('Identification', 'التعريف', language),
            {
              _label('Device', 'الجهاز', language): data.deviceIdentity,
              _label('Firmware', 'البرنامج الثابت', language):
                  data.firmwareVersion,
              _label('Gateway', 'البوابة', language): data.gatewayVersion,
              _label('Profile', 'الملف', language): data.profileVersion,
              _label('Verification', 'التحقق', language):
                  data.profileVerification,
              _label('Technician', 'الفني', language):
                  data.technicianId ?? 'Not provided',
            },
            bold,
            language: language,
          ),
          // يشمل التقرير جميع sessions (وليس الأولى فقط)، تماشياً مع JSON.
          for (final session in data.sessions) ...[
            _section(
              '${_label('Session', 'الجلسة', language)} ${session.id}',
              {
                _label('Scenario', 'السيناريو', language): session.scenario,
                _label('Started', 'بدأت', language): session.startedAt
                    .toUtc()
                    .toIso8601String(),
                _label('Updated', 'حُدثت', language): session.updatedAt
                    .toUtc()
                    .toIso8601String(),
                'SHA-256': session.dataHash,
                _label('Audit head', 'رأس سجل التدقيق', language):
                    data.auditHeads[session.id] ?? 'GENESIS',
              },
              bold,
              language: language,
            ),
            _section(
              _label('Readings', 'القراءات', language),
              {
                for (final entry
                    in (jsonDecode(session.snapshotJson)
                            as Map<String, Object?>)
                        .entries)
                  entry.key: _readableValue(entry.value, data.digitPreference),
              },
              bold,
              language: language,
            ),
            _section(
              _label('Sample series summary', 'ملخص سلسلة العينات', language),
              {
                for (final entry in _sampleSummary(
                  data.samplesBySession[session.id] ?? const [],
                ).entries)
                  entry.key: jsonEncode(entry.value),
              },
              bold,
              language: language,
            ),
            _sampleChart(data.samplesBySession[session.id] ?? const [], bold),
            _section(
              _label('Alarm history', 'سجل الإنذارات', language),
              {
                'alarms': _alarmHistory(
                  data.eventsBySession[session.id] ?? const [],
                ).join(', '),
              },
              bold,
              language: language,
            ),
            _section(
              _label('Findings', 'النتائج', language),
              {
                for (
                  var i = 0;
                  i < (data.findingsBySession[session.id] ?? const []).length;
                  i++
                )
                  '${i + 1}': jsonEncode(
                    (data.findingsBySession[session.id] ?? const [])[i],
                  ),
              },
              bold,
              language: language,
            ),
          ],
          _section(
            _label('Parameters', 'المعلمات', language),
            {
              for (final entry in data.parameters.entries)
                entry.key: '${entry.value}',
            },
            bold,
            language: language,
          ),
          _section(
            _label('Alarm history', 'سجل الإنذارات', language),
            {
              'alarms':
                  data.eventsBySession.values
                      .expand(_alarmHistory)
                      .toSet()
                      .isEmpty
                  ? 'None reported'
                  : data.eventsBySession.values
                        .expand(_alarmHistory)
                        .toSet()
                        .join(', '),
            },
            bold,
            language: language,
          ),
          _section(
            _label('Findings', 'النتائج', language),
            {
              for (var i = 0; i < data.findings.length; i++)
                '${i + 1}':
                    '${data.findings[i]['severity'] ?? 'info'} · ${data.findings[i]['message'] ?? ''}',
            },
            bold,
            language: language,
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<ReportExportResult> export(
    EngineeringReportData data, {
    ReportLanguage language = ReportLanguage.bilingual,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final reports = Directory(
      '${directory.path}${Platform.pathSeparator}SolarDiag Reports',
    );
    await reports.create(recursive: true);
    final id = data.sessions.first.id.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final base = '${reports.path}${Platform.pathSeparator}solardiag_$id';
    final jsonFile = File('$base.json');
    final pdfFile = File('$base.pdf');
    await jsonFile.writeAsString(encodeJson(data), flush: true);
    await pdfFile.writeAsBytes(
      await buildPdf(data, language: language),
      flush: true,
    );
    return ReportExportResult(jsonPath: jsonFile.path, pdfPath: pdfFile.path);
  }

  static void _validate(EngineeringReportData data) {
    final sessions = data.sessions;
    if (sessions.isEmpty) {
      throw StateError('A report requires at least one session.');
    }
    if (sessions.map((item) => item.simulated).toSet().length != 1) {
      throw StateError('Simulated and real sessions cannot be mixed.');
    }
    for (final session in sessions) {
      final samples = data.samplesBySession[session.id] ?? const [];
      final valid = samples.isEmpty
          ? sha256.convert(utf8.encode(session.snapshotJson)).toString() ==
                session.dataHash
          : samples.last.sampleHash == session.dataHash;
      if (!valid) {
        throw StateError(
          'Session integrity verification failed: ${session.id}',
        );
      }
    }
  }

  static Set<String> _alarmHistory(List<DiagnosticEventRecord> events) {
    final alarms = <String>{};
    for (final event in events.where((item) => item.type == 'alarms_changed')) {
      final payload = jsonDecode(event.payloadJson);
      if (payload is Map && payload['codes'] is List) {
        alarms.addAll((payload['codes'] as List).whereType<String>());
      }
    }
    return alarms;
  }

  static Map<String, Object?> _sampleSummary(
    List<TelemetrySampleRecord> samples,
  ) {
    final values = <String, List<double>>{};
    for (final sample in samples) {
      final snapshot = jsonDecode(sample.snapshotJson);
      if (snapshot is! Map) continue;
      for (final field in ['voltage', 'current', 'power', 'soc', 'soh']) {
        final measurement = snapshot[field];
        if (measurement is Map && measurement['value'] is num) {
          values
              .putIfAbsent(field, () => [])
              .add((measurement['value'] as num).toDouble());
        }
      }
    }
    return {
      'sampleCount': samples.length,
      for (final entry in values.entries)
        entry.key: {
          'min': entry.value.reduce((a, b) => a < b ? a : b),
          'max': entry.value.reduce((a, b) => a > b ? a : b),
          'mean': entry.value.reduce((a, b) => a + b) / entry.value.length,
        },
    };
  }

  static pw.Widget _sampleChart(
    List<TelemetrySampleRecord> samples,
    pw.Font bold,
  ) {
    final points = <double>[];
    for (final sample in samples.where((item) => !item.isAggregate)) {
      final snapshot = jsonDecode(sample.snapshotJson);
      if (snapshot is Map && snapshot['soc'] is Map) {
        final value = (snapshot['soc'] as Map)['value'];
        if (value is num) points.add(value.toDouble());
      }
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('SOC sample chart', style: pw.TextStyle(font: bold)),
          pw.SizedBox(height: 6),
          if (points.isEmpty)
            pw.Text('No SOC samples available')
          else
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final point in points.take(40))
                  pw.Container(
                    width: 5,
                    height: (8 + point.clamp(0, 100) * 0.45).toDouble(),
                    margin: const pw.EdgeInsets.only(right: 2),
                    color: PdfColors.green700,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _label(String en, String ar, ReportLanguage language) =>
      switch (language) {
        ReportLanguage.english => en,
        ReportLanguage.arabic => ar,
        ReportLanguage.bilingual => '$en · $ar',
      };

  static String _readableValue(Object? value, DigitPreference digitPreference) {
    if (value is Map<String, Object?>) {
      final reading = value['value'];
      final unit = value['unit'];
      return reading == null
          ? 'Unavailable (${value['absenceReason'] ?? 'not reported'})'
          : '${localizedDigits(reading, digitPreference)}${unit == null || unit == '' ? '' : ' $unit'} · ${value['quality']}';
    }
    return jsonEncode(value);
  }

  static pw.Widget _section(
    String title,
    Map<String, String> values,
    pw.Font bold, {
    required ReportLanguage language,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Align(
          alignment: language == ReportLanguage.arabic
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 13)),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(font: bold),
          headerCount: 0,
          data: [
            for (final entry in values.entries)
              [entry.key, entry.value],
          ],
          tableDirection: language == ReportLanguage.arabic
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(3),
          },
          cellBuilder: (index, data, row) {
            final labelColumn = index == 0;
            final text = '$data';
            return pw.Align(
              alignment: labelColumn && language == ReportLanguage.arabic
                  ? pw.Alignment.centerRight
                  : pw.Alignment.centerLeft,
              child: pw.Directionality(
                textDirection: _hasArabic(text)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    font: labelColumn ? bold : null,
                    fontSize: 8,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  static bool _hasArabic(String value) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}
