import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_analysis.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/findings.dart';
import 'package:solardiag_pro/studio/reference_registry.dart';
import 'package:solardiag_pro/studio/replay_lock.dart';
import 'package:solardiag_pro/studio/research_repository.dart';
import 'package:solardiag_pro/studio/sdcap_codec.dart';

void main() {
  const codec = SdcapCodec();
  final session = CaptureSession(
    id: 'capture-1',
    interfaceType: CaptureInterface.can,
    source: CaptureSource.synthetic,
    startedAt: DateTime.utc(2026),
    frames: const [
      CaptureFrame(
        timestampMicros: 0,
        identifier: 0x351,
        payload: [1, 2, 3],
        received: true,
      ),
      CaptureFrame(
        timestampMicros: 100000,
        identifier: 0x351,
        payload: [1, 4, 3],
        received: true,
      ),
      CaptureFrame(
        timestampMicros: 150000,
        identifier: 0x355,
        payload: [9],
        received: true,
      ),
    ],
    synthetic: true,
    containsNdaMaterial: false,
    notes: 'synthetic test',
  );

  test('.sdcap round trip preserves frames and integrity', () {
    final document = codec.decode(codec.encode(session));
    expect(document.session.frames, hasLength(3));
    expect(document.session.frames[1].payload, [1, 4, 3]);
    expect(document.payloadHash, hasLength(64));
  });
  test('tampered .sdcap payload is rejected', () {
    final root = jsonDecode(codec.encode(session)) as Map<String, Object?>;
    final payload = root['payload']! as Map<String, Object?>;
    payload['notes'] = 'tampered';
    expect(() => codec.decode(jsonEncode(root)), throwsFormatException);
  });
  test('NDA capture cannot be exported', () {
    final restricted = CaptureSession(
      id: 'nda',
      interfaceType: CaptureInterface.can,
      source: CaptureSource.passiveGateway,
      startedAt: DateTime.utc(2026),
      frames: const [],
      synthetic: false,
      containsNdaMaterial: true,
      notes: 'restricted',
    );
    expect(() => codec.encode(restricted), throwsFormatException);
  });
  test('analysis finds timing and changed byte offsets', () {
    final result = const CaptureAnalyzer().analyze(session);
    final stats = result.identifiers[0x351]!;
    expect(stats.frameCount, 2);
    expect(stats.averagePeriodMicros, 100000);
    expect(stats.changedByteOffsets, {1});
  });
  test('differential analysis reports added and changed identifiers', () {
    final baseline = const CaptureAnalyzer().analyze(session);
    final changedSession = CaptureSession(
      id: 'capture-2',
      interfaceType: CaptureInterface.can,
      source: CaptureSource.synthetic,
      startedAt: DateTime.utc(2026),
      frames: const [
        CaptureFrame(
          timestampMicros: 0,
          identifier: 0x351,
          payload: [7, 2, 3],
          received: true,
        ),
        CaptureFrame(
          timestampMicros: 1,
          identifier: 0x360,
          payload: [1],
          received: true,
        ),
      ],
      synthetic: true,
      containsNdaMaterial: false,
      notes: 'changed',
    );
    final result = const DifferentialAnalyzer().compare(
      baseline,
      const CaptureAnalyzer().analyze(changedSession),
    );
    expect(result.onlyInBaseline, {0x355});
    expect(result.onlyInComparison, {0x360});
    expect(result.changedIdentifiers, {0x351});
  });
  test('Replay Lock blocks direct and derived transmissions', () {
    const frame = CaptureFrame(
      timestampMicros: 0,
      identifier: 1,
      payload: [],
      received: true,
    );
    expect(
      () => const ReplayLock().transmitCapturedFrame(frame),
      throwsA(isA<ReplayProhibitedException>()),
    );
    expect(
      () => const ReplayLock().deriveHardwareTransmission(frame),
      throwsA(isA<ReplayProhibitedException>()),
    );
  });
  test(
    'finding cannot jump states or become verified without hardware evidence',
    () {
      const finding = ProtocolFinding(
        id: 'f1',
        title: 'Counter candidate',
        state: FindingState.observation,
        confidence: .2,
        evidence: [],
      );
      expect(
        () => finding.advance(
          FindingState.confirmed,
          newEvidence: const FindingEvidence(
            kind: EvidenceKind.captureFrame,
            reference: 'capture-1:1',
            summary: 'changed',
          ),
        ),
        throwsStateError,
      );
      final hypothesis = finding.advance(
        FindingState.hypothesis,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.captureFrame,
          reference: 'capture-1:1',
          summary: 'changed',
        ),
      );
      final candidate = hypothesis.advance(
        FindingState.candidate,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.differential,
          reference: 'diff-1',
          summary: 'correlated',
        ),
      );
      final confirmed = candidate.advance(
        FindingState.confirmed,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.documentReference,
          reference: 'ref-1',
          summary: 'documented',
        ),
      );
      expect(
        () => confirmed.advance(
          FindingState.verified,
          newEvidence: const FindingEvidence(
            kind: EvidenceKind.documentReference,
            reference: 'ref-2',
            summary: 'more docs',
          ),
        ),
        throwsStateError,
      );
    },
  );
  test('research repository stores sessions and findings', () async {
    final repository = InMemoryResearchRepository();
    await repository.saveSession(session);
    await repository.saveFinding(
      const ProtocolFinding(
        id: 'f1',
        title: 'Observation',
        state: FindingState.observation,
        confidence: .2,
        evidence: [],
      ),
    );
    expect((await repository.session('capture-1'))!.frames, hasLength(3));
    expect(await repository.findings(), hasLength(1));
  });
  test('reference registry rejects unknown and NDA exports', () {
    final registry = ReferenceRegistry.fromJson(
      File('docs/research/references.json').readAsStringSync(),
    );
    expect(
      () => registry.validateExport(['solardiag-simulator-spec-001']),
      returnsNormally,
    );
    expect(() => registry.validateExport(['missing']), throwsFormatException);
  });
  test(
    'analyzes one million frames within desktop budget',
    () {
      final frames = List<CaptureFrame>.generate(
        1000000,
        (index) => CaptureFrame(
          timestampMicros: index * 1000,
          identifier: 0x351 + (index % 4),
          payload: const [1, 2, 3, 4, 5, 6, 7, 8],
          received: true,
        ),
        growable: false,
      );
      final large = CaptureSession(
        id: 'million',
        interfaceType: CaptureInterface.can,
        source: CaptureSource.synthetic,
        startedAt: DateTime.utc(2026),
        frames: frames,
        synthetic: true,
        containsNdaMaterial: false,
        notes: 'performance',
      );
      final watch = Stopwatch()..start();
      final result = const CaptureAnalyzer().analyze(large);
      watch.stop();
      expect(result.totalFrames, 1000000);
      expect(result.identifiers, hasLength(4));
      expect(watch.elapsed, lessThan(const Duration(seconds: 15)));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
