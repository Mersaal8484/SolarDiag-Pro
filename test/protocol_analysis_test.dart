import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_analysis.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/protocol_analysis.dart';

void main() {
  test('boundary detector supports fixed, delimiter, length and idle gap', () {
    const detector = FrameBoundaryDetector();
    final fixed = detector.detectBytes([
      1,
      2,
      3,
      4,
      5,
    ], BoundaryRule.fixedSize(2));
    expect(fixed.frames, [
      [1, 2],
      [3, 4],
    ]);
    expect(fixed.remainder, [5]);

    final delimited = detector.detectBytes([
      1,
      13,
      10,
      2,
      13,
      10,
      3,
    ], BoundaryRule.asciiTerminator());
    expect(delimited.frames, [
      [1, 13, 10],
      [2, 13, 10],
    ]);
    expect(delimited.remainder, [3]);

    final length = detector.detectBytes([
      3,
      1,
      2,
      4,
      7,
      8,
      9,
      5,
    ], BoundaryRule.lengthPrefix(adjustment: 0));
    expect(length.frames, [
      [3, 1, 2],
      [4, 7, 8, 9],
    ]);
    expect(length.remainder, [5]);

    final idle = detector.detectTimedBytes([
      (0, 1),
      (10, 2),
      (100, 3),
    ], BoundaryRule.idleGap(50));
    expect(idle.frames, [
      [1, 2],
      [3],
    ]);
  });

  test('checksum catalog identifies Modbus and CCITT across every frame', () {
    const catalog = ChecksumCatalog();
    final modbusMatches = catalog.findMatches([
      [0x01, 0x03, 0x00, 0x00, 0x00, 0x02, 0xc4, 0x0b],
      [0x01, 0x06, 0x00, 0x01, 0x00, 0x03, 0x98, 0x0b],
    ]);
    expect(
      modbusMatches.any(
        (match) =>
            match.algorithm == ChecksumAlgorithm.crc16Modbus &&
            match.littleEndian,
      ),
      isTrue,
    );
    final ccittMatches = catalog.findMatches([
      [...'123456789'.codeUnits, 0x29, 0xb1],
    ]);
    expect(
      ccittMatches.any(
        (match) =>
            match.algorithm == ChecksumAlgorithm.crc16CcittFalse &&
            !match.littleEndian,
      ),
      isTrue,
    );
  });

  test('request correlation, polling, and Modbus write risk emit evidence', () {
    final session = CaptureSession(
      id: 'protocol-session',
      interfaceType: CaptureInterface.rs485,
      source: CaptureSource.synthetic,
      startedAt: DateTime.utc(2026),
      frames: const [
        CapturedFrame(
          timestampNanos: 0,
          rawBytes: [1, 6, 0, 1, 0, 3],
          direction: CaptureDirection.tx,
          channel: 'a',
          protocolHint: 'Modbus RTU',
        ),
        CapturedFrame(
          timestampNanos: 100,
          rawBytes: [1, 6, 0, 1, 0, 3],
          direction: CaptureDirection.rx,
          channel: 'a',
          protocolHint: 'Modbus RTU',
        ),
        CapturedFrame(
          timestampNanos: 1000,
          rawBytes: [1, 6, 0, 1, 0, 3],
          direction: CaptureDirection.tx,
          channel: 'a',
          protocolHint: 'Modbus RTU',
        ),
        CapturedFrame(
          timestampNanos: 2000,
          rawBytes: [1, 6, 0, 1, 0, 3],
          direction: CaptureDirection.tx,
          channel: 'a',
          protocolHint: 'Modbus RTU',
        ),
      ],
      synthetic: true,
      containsNdaMaterial: false,
      notes: 'synthetic protocol analysis',
    );
    final report = const ProtocolAnalysisEngine().analyze(session);
    expect(report.pairs, hasLength(1));
    expect(report.pollingPatterns.single.count, 3);
    expect(report.modbusFrames.any((frame) => frame.writeRisk), isTrue);
    expect(report.findings, hasLength(3));
    expect(
      report.findings.every((finding) => finding.evidence.isNotEmpty),
      isTrue,
    );
  });

  test('Modbus exception is classified without losing function code', () {
    final classification = const ModbusClassifier().classify([1, 0x83, 2])!;
    expect(classification.functionCode, 3);
    expect(classification.isException, isTrue);
    expect(classification.writeRisk, isFalse);
  });

  test('structural clusters retain frame indices and changed bytes', () {
    final clusters = const FrameClusterer().cluster(const [
      CapturedFrame(
        timestampNanos: 0,
        rawBytes: [1, 2, 3],
        direction: CaptureDirection.rx,
        channel: 'can0',
        identifier: 0x351,
      ),
      CapturedFrame(
        timestampNanos: 1,
        rawBytes: [1, 9, 3],
        direction: CaptureDirection.rx,
        channel: 'can0',
        identifier: 0x351,
      ),
    ]);

    expect(clusters, hasLength(1));
    expect(clusters.single.frameIndices, [0, 1]);
    expect(clusters.single.changedByteOffsets, {1});
  });

  test('capture analysis can run in an isolate', () async {
    final session = CaptureSession(
      id: 'isolate-session',
      interfaceType: CaptureInterface.can,
      source: CaptureSource.synthetic,
      startedAt: DateTime.utc(2026),
      frames: const [
        CapturedFrame(
          timestampNanos: 0,
          rawBytes: [1, 2],
          direction: CaptureDirection.rx,
          channel: 'can0',
          identifier: 0x123,
        ),
      ],
      synthetic: true,
      containsNdaMaterial: false,
      notes: 'synthetic isolate analysis',
    );

    final analysis = await const CaptureAnalyzer().analyzeInIsolate(session);

    expect(analysis.totalFrames, 1);
    expect(analysis.identifiers, contains(0x123));
  });
}
