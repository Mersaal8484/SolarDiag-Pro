import 'dart:collection';

import 'capture_analysis.dart';
import 'capture_models.dart';

class StreamingAnalysisBudget {
  const StreamingAnalysisBudget({
    this.maximumIdentifiers = 4096,
    this.maximumClusters = 4096,
    this.maximumPendingRequests = 256,
    this.maximumTrackedPayloadBytes = 256,
  });

  final int maximumIdentifiers;
  final int maximumClusters;
  final int maximumPendingRequests;
  final int maximumTrackedPayloadBytes;
}

class StreamingChecksumSummary {
  const StreamingChecksumSummary({
    required this.additive8Matches,
    required this.xor8Matches,
    required this.eligibleFrames,
  });
  final int additive8Matches;
  final int xor8Matches;
  final int eligibleFrames;
}

class StreamingAnalysisResult {
  const StreamingAnalysisResult({
    required this.capture,
    required this.boundaryGapCount,
    required this.requestResponsePairs,
    required this.clusterCount,
    required this.checksums,
    required this.droppedIdentifierCount,
    required this.peakPendingRequests,
    required this.estimatedPeakBytes,
  });

  final CaptureAnalysis capture;
  final int boundaryGapCount;
  final int requestResponsePairs;
  final int clusterCount;
  final StreamingChecksumSummary checksums;
  final int droppedIdentifierCount;
  final int peakPendingRequests;
  final int estimatedPeakBytes;
}

class StreamingCaptureAnalyzer {
  const StreamingCaptureAnalyzer({
    this.budget = const StreamingAnalysisBudget(),
    this.boundaryGapNanos = 100000000,
    this.maximumResponseLatencyNanos = 1000000000,
  });

  final StreamingAnalysisBudget budget;
  final int boundaryGapNanos;
  final int maximumResponseLatencyNanos;

  Future<StreamingAnalysisResult> analyze(
    Stream<CapturedFrame> frames, {
    void Function(int processedFrames)? onProgress,
  }) async {
    final identifiers = <int, _IdentifierAccumulator>{};
    final clusters = <int?, Map<int, Set<CaptureDirection>>>{};
    var clusterCount = 0;
    final pending = ListQueue<_PendingRequest>();
    var total = 0;
    var boundaryGaps = 0;
    var pairs = 0;
    var droppedIdentifiers = 0;
    var peakPending = 0;
    var eligibleChecksums = 0;
    var additiveMatches = 0;
    var xorMatches = 0;
    int? previousTimestamp;

    void processFrame(CapturedFrame frame) {
      total++;
      if (total % 65536 == 0) {
        onProgress?.call(total);
      }
      final priorTimestamp = previousTimestamp;
      if (priorTimestamp != null &&
          frame.timestampNanos - priorTimestamp > boundaryGapNanos) {
        boundaryGaps++;
      }
      previousTimestamp = frame.timestampNanos;

      final identifier = frame.identifier;
      if (identifier != null) {
        var accumulator = identifiers[identifier];
        if (accumulator == null) {
          if (identifiers.length < budget.maximumIdentifiers) {
            accumulator = _IdentifierAccumulator(
              identifier,
              budget.maximumTrackedPayloadBytes,
            );
            identifiers[identifier] = accumulator;
          } else {
            droppedIdentifiers++;
          }
        }
        accumulator?.add(frame);
      }

      if (clusterCount < budget.maximumClusters) {
        final lengths = clusters[identifier] ??= {};
        final directions = lengths[frame.rawBytes.length] ??= {};
        if (directions.add(frame.direction)) clusterCount++;
      }

      if (frame.rawBytes.length >= 2) {
        eligibleChecksums++;
        final expected = frame.rawBytes.last;
        var additive = 0;
        var xor = 0;
        for (var index = 0; index < frame.rawBytes.length - 1; index++) {
          final value = frame.rawBytes[index];
          additive += value;
          xor ^= value;
        }
        if ((additive & 0xff) == expected) {
          additiveMatches++;
        }
        if (xor == expected) xorMatches++;
      }

      while (pending.isNotEmpty &&
          frame.timestampNanos - pending.first.timestampNanos >
              maximumResponseLatencyNanos) {
        pending.removeFirst();
      }
      if (frame.direction == CaptureDirection.tx) {
        if (pending.length == budget.maximumPendingRequests) {
          pending.removeFirst();
        }
        pending.addLast(_PendingRequest(frame.timestampNanos, frame.channel));
        if (pending.length > peakPending) {
          peakPending = pending.length;
        }
      } else if (frame.direction == CaptureDirection.rx) {
        _PendingRequest? match;
        for (final request in pending) {
          if (request.channel == frame.channel) {
            match = request;
            break;
          }
        }
        if (match != null) {
          pending.remove(match);
          pairs++;
        }
      }
    }

    StreamingAnalysisResult finish() {
      final statistics = <int, IdentifierStatistics>{
        for (final entry in identifiers.entries)
          entry.key: entry.value.finish(),
      };
      final estimate =
          identifiers.length * (96 + budget.maximumTrackedPayloadBytes * 2) +
          clusterCount * 32 +
          budget.maximumPendingRequests * 40;
      return StreamingAnalysisResult(
        capture: CaptureAnalysis(
          totalFrames: total,
          identifiers: Map.unmodifiable(statistics),
        ),
        boundaryGapCount: boundaryGaps,
        requestResponsePairs: pairs,
        clusterCount: clusterCount,
        checksums: StreamingChecksumSummary(
          additive8Matches: additiveMatches,
          xor8Matches: xorMatches,
          eligibleFrames: eligibleChecksums,
        ),
        droppedIdentifierCount: droppedIdentifiers,
        peakPendingRequests: peakPending,
        estimatedPeakBytes: estimate,
      );
    }

    await for (final frame in frames) {
      processFrame(frame);
    }
    return finish();
  }
}

class _IdentifierAccumulator {
  _IdentifierAccumulator(this.identifier, this.maximumBytes);
  final int identifier;
  final int maximumBytes;
  int count = 0;
  int? firstTimestampMicros;
  int? lastTimestampMicros;
  int minimumLength = 1 << 30;
  int maximumLength = 0;
  final List<int?> firstValues = [];
  final Set<int> changedOffsets = {};

  void add(CapturedFrame frame) {
    count++;
    firstTimestampMicros ??= frame.timestampMicros;
    lastTimestampMicros = frame.timestampMicros;
    if (frame.rawBytes.length < minimumLength) {
      minimumLength = frame.rawBytes.length;
    }
    if (frame.rawBytes.length > maximumLength) {
      maximumLength = frame.rawBytes.length;
    }
    final tracked = frame.rawBytes.length > maximumBytes
        ? maximumBytes
        : frame.rawBytes.length;
    while (firstValues.length < tracked) {
      firstValues.add(null);
    }
    for (var offset = 0; offset < tracked; offset++) {
      final first = firstValues[offset];
      if (first == null) {
        firstValues[offset] = frame.rawBytes[offset];
      } else if (first != frame.rawBytes[offset]) {
        changedOffsets.add(offset);
      }
    }
  }

  IdentifierStatistics finish() => IdentifierStatistics(
    identifier: identifier,
    frameCount: count,
    averagePeriodMicros: count > 1
        ? (lastTimestampMicros! - firstTimestampMicros!) / (count - 1)
        : null,
    minimumPayloadLength: minimumLength == 1 << 30 ? 0 : minimumLength,
    maximumPayloadLength: maximumLength,
    changedByteOffsets: Set.unmodifiable(changedOffsets),
  );
}

class _PendingRequest {
  const _PendingRequest(this.timestampNanos, this.channel);
  final int timestampNanos;
  final String channel;
}
