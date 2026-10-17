import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/persistence/local_database.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/findings.dart';
import 'package:solardiag_pro/studio/research_bundle.dart';
import 'package:solardiag_pro/studio/research_repository.dart';

void main() {
  CaptureSession session({bool nda = false}) => CaptureSession(
    id: nda ? 'restricted' : 'shareable',
    interfaceType: CaptureInterface.can,
    source: CaptureSource.synthetic,
    startedAt: DateTime.utc(2026),
    frames: const [
      CapturedFrame(
        timestampNanos: 1,
        rawBytes: [1, 2, 3],
        direction: CaptureDirection.rx,
        channel: 'can0',
        identifier: 0x351,
      ),
    ],
    synthetic: true,
    containsNdaMaterial: nda,
    notes: 'research persistence fixture',
  );

  final finding = ProtocolFinding.observation(
    id: 'finding-1',
    title: 'Synthetic counter candidate',
    evidence: const [
      FindingEvidence(
        kind: EvidenceKind.captureFrame,
        reference: 'shareable:0',
        summary: 'Synthetic frame',
        captureId: 'shareable',
      ),
    ],
  );

  test('SQLite restores research sessions and findings', () async {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final repository = LocalResearchRepository(database);

    await repository.saveSession(session(nda: true));
    await repository.saveFinding(finding);

    final restoredSession = await repository.session('restricted');
    final restoredFindings = await repository.findings();
    expect(restoredSession!.containsNdaMaterial, isTrue);
    expect(restoredSession.frames.single.identifier, 0x351);
    expect(restoredFindings.single.id, finding.id);
    expect(restoredFindings.single.evidence.single.reference, 'shareable:0');
  });

  test('research bundle round trip preserves integrity and references', () {
    const codec = ResearchBundleCodec();
    final encoded = codec.encode(
      sessions: [session()],
      findings: [finding],
      referenceIds: const ['ref-b', 'ref-a', 'ref-a'],
    );
    final decoded = codec.decode(encoded);

    expect(decoded.sessions.single.id, 'shareable');
    expect(decoded.findings.single.id, 'finding-1');
    expect(decoded.referenceIds, ['ref-a', 'ref-b']);
    expect(decoded.payloadHash, hasLength(64));
  });

  test('research bundle rejects NDA sessions and tampering', () {
    const codec = ResearchBundleCodec();
    expect(
      () => codec.encode(sessions: [session(nda: true)], findings: const []),
      throwsFormatException,
    );

    final root =
        jsonDecode(codec.encode(sessions: [session()], findings: [finding]))
            as Map<String, Object?>;
    final payload = root['payload']! as Map<String, Object?>;
    payload['reference_ids'] = ['injected'];
    expect(() => codec.decode(jsonEncode(root)), throwsFormatException);
  });
}
