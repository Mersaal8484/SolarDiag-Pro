import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_analysis.dart';
import 'package:solardiag_pro/studio/capture_importers.dart';
import 'package:solardiag_pro/studio/differential_analysis.dart';
import 'package:solardiag_pro/studio/findings.dart';
import 'package:solardiag_pro/studio/hypothesis.dart';
import 'package:solardiag_pro/studio/profile_builder.dart';
import 'package:solardiag_pro/studio/protocol_analysis.dart';
import 'package:solardiag_pro/studio/replay_lock.dart';
import 'package:solardiag_pro/studio/research_bundle.dart';
import 'package:solardiag_pro/studio/synthetic_capture_suite.dart';
import 'package:solardiag_pro/studio/validation_runner.dart';
import 'package:solardiag_pro/protocol/profile_registry.dart';

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

  test('G5 import through offline validation and safe export is complete', () {
    final context = CaptureImportContext(
      sessionId: 'e2e-import',
      startedAt: DateTime.utc(2026),
      synthetic: false,
      containsNdaMaterial: false,
      clockSource: 'logic-analyzer',
      clockAccuracyNanos: 1000,
    );
    final imported = const CaptureImportWizard()
        .preview(
          fileName: 'capture.candump',
          source: '(1.0) can0 351#0102\n(1.1) can0 351#0103',
          context: context,
        )
        .result
        .session!;
    final comparison = const CaptureImportWizard()
        .preview(
          fileName: 'comparison.candump',
          source: '(1.0) can0 351#0202\n(1.1) can0 351#0203',
          context: CaptureImportContext(
            sessionId: 'e2e-comparison',
            startedAt: DateTime.utc(2026),
            synthetic: false,
            containsNdaMaterial: false,
          ),
        )
        .result
        .session!;

    final analysis = const CaptureAnalyzer().analyze(imported);
    final differential = const SafeDifferentialAnalyzer().compare(
      imported,
      comparison,
      baselineRepeat: imported,
    );
    expect(analysis.totalFrames, 2);
    expect(differential.candidates, isNotEmpty);

    final hypothesis = ProtocolHypothesis(
      id: 'hypothesis-soc',
      claim: 'Identifier 0x351 byte 0 may encode SOC.',
      evidenceReferences: differential.candidates.first.evidence,
      confidence: differential.candidates.first.score,
      fieldIdentifier: 0x351,
      byteOffset: 0,
    );
    expect(hypothesis.toJson()['transmittable'], isFalse);
    expect(
      () => const ReplayLock().transmitHypothesis(hypothesis),
      throwsA(isA<ReplayProhibitedException>()),
    );

    const draft = StudioProfileDraft(
      id: 'studio.e2e.can.v2',
      manufacturer: 'Research',
      family: 'Offline fixture',
      referenceIds: ['solardiag-simulator-spec-001'],
      mappings: [
        FieldMapping(
          field: 'state_of_charge',
          frameIdentifier: 0x351,
          offset: 0,
          length: 1,
          dataType: FieldDataType.unsigned8,
          scale: 1,
          unit: '%',
          evidenceReferences: ['e2e-import:0', 'e2e-comparison:0'],
        ),
      ],
    );
    final validation = const StudioValidationRunner().validate(
      OfflineValidationRequest(
        draft: draft,
        session: imported,
        mockResponses: {
          0x351: [3, 4],
        },
        expectedIdentity: 'offline-fixture',
        observedIdentity: 'offline-fixture',
      ),
    );
    expect(validation.passed, isTrue);
    expect(validation.generatedParserTests, isNotEmpty);

    final releaseGate = const StudioReleaseGate().evaluate(
      StudioReleaseGateRequest(
        validation: validation,
        legalReviewCompleted: false,
        containsNdaMaterial: false,
        physicalHardwareValidated: false,
      ),
    );
    expect(releaseGate.canRequestPublication, isFalse);
    expect(releaseGate.blockers, contains('legal_review_incomplete'));
    expect(releaseGate.checklistPath, 'docs/studio/LEGAL_REVIEW_CHECKLIST.md');

    final exported = const ProfileBuilder().exportStudioDraft(draft);
    expect(exported, contains('"schema_version": 2'));
    expect(exported, contains('"status": "studio-draft"'));
    expect(
      () => ProfileRegistry.fromJsonDocuments([exported], technicianMode: true),
      throwsFormatException,
    );
  });
}
