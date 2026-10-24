import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/streaming_analysis.dart';

void main() {
  test(
    'G4 streaming analyzer handles one million frames within bounded state',
    () async {
      const count = 1000000;
      final baselineRss = ProcessInfo.currentRss;
      var peakRss = baselineRss;
      final stopwatch = Stopwatch()..start();
      final result = await const StreamingCaptureAnalyzer().analyze(
        _frames(count),
        onProgress: (_) {
          final current = ProcessInfo.currentRss;
          if (current > peakRss) {
            peakRss = current;
          }
        },
      );
      stopwatch.stop();
      final peakDelta = peakRss - baselineRss;

      // ignore: avoid_print
      print(
        'G4_PERF frames=$count elapsed_ms=${stopwatch.elapsedMilliseconds} '
        'baseline_rss=$baselineRss peak_rss=$peakRss '
        'sampled_peak_rss_delta=$peakDelta '
        'bounded_state_bytes=${result.estimatedPeakBytes}',
      );
      expect(result.capture.totalFrames, count);
      expect(result.capture.identifiers, hasLength(16));
      expect(result.clusterCount, lessThanOrEqualTo(4096));
      expect(result.peakPendingRequests, lessThanOrEqualTo(256));
      expect(result.estimatedPeakBytes, lessThan(8 * 1024 * 1024));
      expect(
        peakDelta,
        lessThan(256 * 1024 * 1024),
        reason: 'Sampled RSS growth budget for a streamed million-frame run.',
      );
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 30)),
        reason: 'Documented desktop test budget for one million frames.',
      );
    },
  );
}

Stream<CapturedFrame> _frames(int count) async* {
  final frames = List<CapturedFrame>.generate(
    32,
    (index) => CapturedFrame(
      timestampNanos: 0,
      identifier: 0x300 + index ~/ 2,
      rawBytes: const [0, 0, 0, 0, 0, 0, 0, 0],
      direction: index.isEven ? CaptureDirection.tx : CaptureDirection.rx,
      channel: 'bench',
    ),
    growable: false,
  );
  for (var index = 0; index < count; index++) {
    yield frames[index % frames.length];
    if ((index + 1) % 8192 == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
