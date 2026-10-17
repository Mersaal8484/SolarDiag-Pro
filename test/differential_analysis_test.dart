import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/differential_analysis.dart';
import 'package:solardiag_pro/studio/findings.dart';

void main() {
  CaptureSession session(String id, List<int> values) => CaptureSession(
    id: id,
    interfaceType: CaptureInterface.can,
    source: CaptureSource.synthetic,
    startedAt: DateTime.utc(2026),
    frames: [
      for (var index = 0; index < values.length; index++)
        CapturedFrame(
          timestampNanos: index * 1000,
          rawBytes: [values[index], 0x55],
          direction: CaptureDirection.rx,
          channel: 'can0',
          identifier: 0x351,
        ),
    ],
    synthetic: true,
    containsNdaMaterial: false,
    notes: 'synthetic differential fixture',
  );

  test('ranks changed bytes and bits with traceable evidence', () {
    final report = const SafeDifferentialAnalyzer().compare(
      session('a', [0, 0, 0]),
      session('b', [1, 1, 1]),
    );

    expect(report.candidates.first.identifier, 0x351);
    expect(report.candidates.first.byteOffset, 0);
    expect(report.candidates.first.score, 1);
    expect(report.candidates.any((item) => item.bitIndex == 0), isTrue);
    expect(report.candidates.every((item) => item.evidence.isNotEmpty), isTrue);
    expect(report.summary.changedIdentifiers, contains(0x351));
    expect(report.findings.first.state, FindingState.observation);
    expect(report.findings.first.evidence, isNotEmpty);
  });

  test('A/B/A repeat is evidence but does not auto-confirm a finding', () {
    final report = const SafeDifferentialAnalyzer().compare(
      session('a1', [0, 0, 0]),
      session('b', [4, 4, 4]),
      baselineRepeat: session('a2', [0, 0, 0]),
    );

    expect(report.candidates.first.repeatedAba, isTrue);
    expect(
      report.findings.first.evidence
          .where((item) => item.kind == EvidenceKind.differential)
          .single
          .repeatedAba,
      isTrue,
    );
    expect(report.findings.first.state, FindingState.observation);
  });

  test('unchanged fields do not produce differential candidates', () {
    final report = const SafeDifferentialAnalyzer().compare(
      session('a', [7, 7]),
      session('b', [7, 7]),
    );

    expect(report.candidates, isEmpty);
    expect(report.findings, isEmpty);
  });

  test('candidate count is bounded for large captures', () {
    final report = SafeDifferentialAnalyzer(
      maximumCandidates: 2,
    ).compare(session('a', [0, 0]), session('b', [255, 255]));

    expect(report.candidates, hasLength(2));
  });
}
