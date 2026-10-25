import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/findings.dart';
import 'package:solardiag_pro/studio/inference_analysis.dart';
import 'package:solardiag_pro/studio/synthetic_capture_suite.dart';

void main() {
  const engine = AdvancedInferenceEngine();

  test('synthetic Modbus identifies address and derived response timing', () {
    final report = engine.analyze(
      SyntheticCaptureSuite.modbusPolling.frames,
      captureId: SyntheticCaptureSuite.modbusPolling.id,
    );

    expect(report.addressFields.first.offset, 0);
    expect(report.addressFields.first.distinctValues, {1});
    expect(report.responseTiming!.pairCount, 4);
    expect(report.responseTiming!.percentile95Nanos, 5000000);
    expect(report.responseTiming!.derivedTimeoutNanos, greaterThan(5000000));
    expect(report.responseTiming!.recommendationLabel, 'derived');
  });

  test('synthetic payloads distinguish fixed and length-field framing', () {
    final fixed = engine.analyze(
      SyntheticCaptureSuite.canCounter.frames,
      captureId: SyntheticCaptureSuite.canCounter.id,
    );
    final prefixed = engine.analyze(
      SyntheticCaptureSuite.lengthField.frames,
      captureId: SyntheticCaptureSuite.lengthField.id,
    );

    expect(fixed.payloadLength.mode, PayloadLengthMode.fixed);
    expect(fixed.payloadLength.fixedLength, 3);
    expect(prefixed.payloadLength.mode, PayloadLengthMode.lengthField);
    expect(prefixed.payloadLength.lengthFieldOffset, 0);
    expect(prefixed.payloadLength.lengthAdjustment, 0);
  });

  test('synthetic text fixture yields ASCII, BCD and hex-ASCII candidates', () {
    final report = engine.analyze(
      SyntheticCaptureSuite.textEncodings.frames,
      captureId: SyntheticCaptureSuite.textEncodings.id,
    );

    expect(
      report.textCandidates.map((candidate) => candidate.kind),
      containsAll(TextEncodingKind.values),
    );
    expect(
      report.textCandidates
          .firstWhere((candidate) => candidate.kind == TextEncodingKind.ascii)
          .sample,
      'HELLO',
    );
    expect(
      report.textCandidates
          .firstWhere(
            (candidate) => candidate.kind == TextEncodingKind.hexAscii,
          )
          .sample,
      'AB',
    );
  });

  test('synthetic CAN ranks physical numeric interpretation from evidence', () {
    final report = engine.analyze(
      SyntheticCaptureSuite.canCounter.frames,
      captureId: SyntheticCaptureSuite.canCounter.id,
    );
    final voltage = report.numericInterpretations.firstWhere(
      (candidate) =>
          candidate.identifier == 0x351 &&
          candidate.byteOffset == 0 &&
          !candidate.littleEndian &&
          !candidate.signed &&
          candidate.scale == .1,
    );

    expect(voltage.minimum, closeTo(55.2, .0001));
    expect(voltage.maximum, closeTo(55.2, .0001));
    expect(voltage.confidence, .95);
    expect(voltage.evidence, contains('40-60 V for 16S LiFePO4'));
  });

  test('synthetic CAN produces bit correlation and signal boundaries', () {
    final report = engine.analyze(
      SyntheticCaptureSuite.canCounter.frames,
      captureId: SyntheticCaptureSuite.canCounter.id,
    );

    expect(report.bitfields, isNotEmpty);
    expect(
      report.bitfields.every((candidate) => candidate.toggleCount > 0),
      isTrue,
    );
    expect(report.canSignals.single.identifier, 0x351);
    expect(report.canSignals.single.startBit, 16);
    expect(report.canSignals.single.length, greaterThanOrEqualTo(4));
  });

  test('all inference findings are computed observations, never verified', () {
    final report = engine.analyze(
      SyntheticCaptureSuite.modbusPolling.frames,
      captureId: SyntheticCaptureSuite.modbusPolling.id,
    );

    expect(report.findings, isNotEmpty);
    expect(
      report.findings.every(
        (finding) =>
            finding.state == FindingState.observation &&
            finding.state != FindingState.verified &&
            finding.evidence.isNotEmpty,
      ),
      isTrue,
    );
  });

  test(
    'one million synthetic frames use deterministic bounded analysis state',
    () {
      final report = engine.analyze(
        _millionSyntheticFrames(),
        captureId: 'synthetic-million-inference',
      );

      expect(report.processedFrames, 1000000);
      expect(report.canSignals.single.identifier, 0x351);
      expect(report.estimatedPeakBytes, lessThan(1000000));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

Iterable<CapturedFrame> _millionSyntheticFrames() sync* {
  for (var index = 0; index < 1000000; index++) {
    yield CapturedFrame(
      timestampNanos: index * 1000000,
      rawBytes: [0x02, 0x28, index & 0xff],
      direction: CaptureDirection.rx,
      channel: 'synthetic-can',
      identifier: 0x351,
      protocolHint: 'Synthetic CAN',
    );
  }
}
