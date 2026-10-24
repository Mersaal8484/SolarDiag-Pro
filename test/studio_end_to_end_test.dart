import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_analysis.dart';
import 'package:solardiag_pro/studio/findings.dart';
import 'package:solardiag_pro/studio/protocol_analysis.dart';
import 'package:solardiag_pro/studio/research_bundle.dart';
import 'package:solardiag_pro/studio/synthetic_capture_suite.dart';

void main() {
  test('synthetic suite is deterministic and export-safe', () {
    final sessions = SyntheticCaptureSuite.all;

    expect(sessions, hasLength(3));
    expect(sessions.map((item) => item.id).toSet(), hasLength(3));
    expect(sessions.every((item) => item.synthetic), isTrue);
    expect(sessions.every((item) => !item.containsNdaMaterial), isTrue);
    expect(sessions.every((item) => item.frames.isNotEmpty), isTrue);
  });

  test('capture to analysis to integrity bundle works end to end', () {
    const captureAnalyzer = CaptureAnalyzer();
    const protocolAnalyzer = ProtocolAnalysisEngine();
    final findings = <ProtocolFinding>[];

    for (final session in SyntheticCaptureSuite.all) {
      expect(
        captureAnalyzer.analyze(session).totalFrames,
        session.frames.length,
      );
      findings.addAll(protocolAnalyzer.analyze(session).findings);
    }

    const codec = ResearchBundleCodec();
    final encoded = codec.encode(
      sessions: SyntheticCaptureSuite.all,
      findings: findings,
      referenceIds: const ['solardiag-simulator-spec-001'],
    );
    final restored = codec.decode(encoded);

    expect(restored.sessions, hasLength(3));
    expect(restored.findings, isNotEmpty);
    expect(restored.referenceIds, ['solardiag-simulator-spec-001']);
    expect(restored.payloadHash, hasLength(64));
  });

  test('Modbus fixture yields correlated polling evidence', () {
    final report = const ProtocolAnalysisEngine().analyze(
      SyntheticCaptureSuite.modbusPolling,
    );

    expect(report.pairs, hasLength(4));
    expect(report.pollingPatterns, isNotEmpty);
    expect(report.modbusFrames, hasLength(8));
    expect(report.findings.every((item) => item.evidence.isNotEmpty), isTrue);
  });
}
