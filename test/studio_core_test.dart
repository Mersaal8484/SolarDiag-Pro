import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
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
    expect(document.sourceSchemaVersion, 2);
    expect(document.session.frames, hasLength(3));
    expect(document.session.frames[1].payload, [1, 4, 3]);
    expect(document.payloadHash, hasLength(64));
    expect(document.session.integrityHash, document.payloadHash);
    expect(document.session.frames.first.direction, CaptureDirection.rx);
  });
  test('.sdcap v1 reader migrates legacy microsecond CAN frames', () {
    final payload = <String, Object?>{
      'id': 'legacy',
      'interface': 'can',
      'source': 'candump',
      'started_at': DateTime.utc(2025).toIso8601String(),
      'synthetic': false,
      'notes': 'legacy capture',
      'frames': [
        {
          'timestamp_us': 123,
          'identifier': 0x18ff50e5,
          'payload': [1, 2],
          'received': false,
          'extended': true,
        },
      ],
    };
    final hash = sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    final document = codec.decode(
      jsonEncode({
        'magic': SdcapCodec.magic,
        'schema_version': 1,
        'payload': payload,
        'sha256': hash,
      }),
    );
    expect(document.sourceSchemaVersion, 1);
    expect(document.session.frames.single.timestampNanos, 123000);
    expect(document.session.frames.single.direction, CaptureDirection.tx);
    expect(document.session.frames.single.extendedIdentifier, isTrue);
  });
  test('.sdcap v2 preserves generic serial and network metadata', () {
    final generic = CaptureSession(
      id: 'generic-v2',
      interfaceType: CaptureInterface.rs485,
      source: CaptureSource.genericText,
      startedAt: DateTime.utc(2026),
      frames: const [
        CapturedFrame(
          timestampNanos: 99,
          rawBytes: [1, 3, 0, 0],
          direction: CaptureDirection.unknown,
          channel: 'rs485-a',
          sourceAddress: '1',
          destinationAddress: 'master',
          errorFlags: ['truncated'],
          protocolHint: 'Modbus RTU',
        ),
      ],
      synthetic: true,
      containsNdaMaterial: false,
      notes: 'generic frame',
      serialConfiguration: const {'baud_rate': 9600, 'format': '8N1'},
      deviceMetadata: const {'model': 'synthetic'},
      clockSource: 'gateway-monotonic',
      clockAccuracyNanos: 100,
    );
    final decoded = codec.decode(codec.encode(generic)).session;
    expect(decoded.serialConfiguration['baud_rate'], 9600);
    expect(decoded.deviceMetadata['model'], 'synthetic');
    expect(decoded.frames.single.identifier, isNull);
    expect(decoded.frames.single.errorFlags, ['truncated']);
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
      final audit = AuditChain(clock: () => DateTime.utc(2026));
      final finding = ProtocolFinding.observation(
        id: 'f1',
        title: 'Counter candidate',
      );
      const analyst = FindingActor(
        id: 'analyst-1',
        role: FindingRole.analyst,
        authenticated: true,
      );
      expect(
        () => finding.advance(
          FindingState.confirmed,
          newEvidence: const FindingEvidence(
            kind: EvidenceKind.captureFrame,
            reference: 'capture-1:1',
            summary: 'changed',
          ),
          actor: analyst,
          at: DateTime.utc(2026),
          audit: audit,
        ),
        throwsStateError,
      );
      final hypothesis = finding.advance(
        FindingState.hypothesis,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.captureFrame,
          reference: 'capture-1:1',
          summary: 'changed',
          captureId: 'capture-1',
        ),
        actor: analyst,
        at: DateTime.utc(2026, 1, 2),
        audit: audit,
      );
      final candidate = hypothesis.advance(
        FindingState.candidate,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.differential,
          reference: 'diff-1',
          summary: 'correlated',
        ),
        actor: analyst,
        at: DateTime.utc(2026, 1, 3),
        audit: audit,
      );
      final confirmed = candidate.advance(
        FindingState.confirmed,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.documentReference,
          reference: 'ref-1',
          summary: 'documented',
        ),
        actor: analyst,
        at: DateTime.utc(2026, 1, 4),
        audit: audit,
      );
      expect(confirmed.confidence, hypothesis.confidence);
      expect(
        () => confirmed.advance(
          FindingState.verified,
          newEvidence: const FindingEvidence(
            kind: EvidenceKind.documentReference,
            reference: 'ref-2',
            summary: 'more docs',
          ),
          actor: const FindingActor(
            id: 'engineer-1',
            role: FindingRole.approvalEngineer,
            authenticated: true,
          ),
          at: DateTime.utc(2026, 1, 5),
          audit: audit,
        ),
        throwsStateError,
      );
      final verified = confirmed.advance(
        FindingState.verified,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.hardwareValidation,
          reference: 'hardware-run-1',
          summary: 'Validated on isolated hardware',
        ),
        actor: const FindingActor(
          id: 'engineer-1',
          role: FindingRole.approvalEngineer,
          authenticated: true,
        ),
        at: DateTime.utc(2026, 1, 5),
        audit: audit,
      );
      expect(verified.state, FindingState.verified);
      expect(verified.promotions.last.auditHash, audit.head);
    },
  );
  test('research repository stores sessions and findings', () async {
    final repository = InMemoryResearchRepository();
    await repository.saveSession(session);
    await repository.saveFinding(
      ProtocolFinding.observation(id: 'f1', title: 'Observation'),
    );
    expect((await repository.session('capture-1'))!.frames, hasLength(3));
    expect(await repository.findings(), hasLength(1));
  });
  test('finding rejection is terminal and audited', () {
    final audit = AuditChain(clock: () => DateTime.utc(2026));
    final rejected =
        ProtocolFinding.observation(
          id: 'rejected-finding',
          title: 'Unsupported mapping',
        ).reject(
          actor: const FindingActor(
            id: 'analyst-1',
            role: FindingRole.analyst,
            authenticated: true,
          ),
          at: DateTime.utc(2026),
          reason: 'A/B/A capture contradicted the hypothesis',
          audit: audit,
        );
    expect(rejected.state, FindingState.rejected);
    expect(rejected.promotions.single.auditHash, audit.head);
    expect(
      () => rejected.advance(
        FindingState.verified,
        newEvidence: const FindingEvidence(
          kind: EvidenceKind.hardwareValidation,
          reference: 'hardware-1',
          summary: 'late evidence',
        ),
        actor: const FindingActor(
          id: 'engineer-1',
          role: FindingRole.approvalEngineer,
          authenticated: true,
        ),
        at: DateTime.utc(2026, 1, 2),
        audit: audit,
      ),
      throwsStateError,
    );
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
    expect(
      registry.thirdPartyNotices(),
      contains('LicenseRef-FRECON-Proprietary'),
    );
    for (final id in const [
      'syssi-esphome-pipsolar',
      'syssi-esphome-jk-bms',
      'syssi-esphome-daly-bms',
      'mpp-solar-protocols',
    ]) {
      final reference = registry.references[id];
      expect(reference, isNotNull, reason: id);
      expect(reference!.exactVersion, matches(RegExp(r'^[0-9a-f]{40}$')));
      expect(reference.maintenanceStatus, isNotEmpty);
    }
  });
  test('reference registry reports malformed fields as format errors', () {
    expect(
      () => ReferenceRegistry.fromJson('{"references":[{"id":7}]}'),
      throwsFormatException,
    );
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
