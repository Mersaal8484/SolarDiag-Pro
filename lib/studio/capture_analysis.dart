import 'dart:isolate';

import 'capture_models.dart';

class IdentifierStatistics {
  const IdentifierStatistics({
    required this.identifier,
    required this.frameCount,
    required this.averagePeriodMicros,
    required this.minimumPayloadLength,
    required this.maximumPayloadLength,
    required this.changedByteOffsets,
  });
  final int identifier;
  final int frameCount;
  final double? averagePeriodMicros;
  final int minimumPayloadLength;
  final int maximumPayloadLength;
  final Set<int> changedByteOffsets;
}

class CaptureAnalysis {
  const CaptureAnalysis({required this.totalFrames, required this.identifiers});
  final int totalFrames;
  final Map<int, IdentifierStatistics> identifiers;
}

class CaptureAnalyzer {
  const CaptureAnalyzer();
  Future<CaptureAnalysis> analyzeInIsolate(CaptureSession session) =>
      Isolate.run(() => analyze(session));

  CaptureAnalysis analyze(CaptureSession session) {
    final groups = <int, List<CaptureFrame>>{};
    for (final frame in session.frames) {
      final identifier = frame.identifier;
      if (identifier != null) {
        (groups[identifier] ??= []).add(frame);
      }
    }
    final result = <int, IdentifierStatistics>{};
    for (final entry in groups.entries) {
      final frames = entry.value
        ..sort((a, b) => a.timestampMicros.compareTo(b.timestampMicros));
      var periodSum = 0;
      for (var i = 1; i < frames.length; i++) {
        periodSum += frames[i].timestampMicros - frames[i - 1].timestampMicros;
      }
      final minLength = frames
          .map((frame) => frame.payload.length)
          .reduce((a, b) => a < b ? a : b);
      final maxLength = frames
          .map((frame) => frame.payload.length)
          .reduce((a, b) => a > b ? a : b);
      final changed = <int>{};
      for (var offset = 0; offset < maxLength; offset++) {
        final values = <int?>{
          for (final frame in frames)
            offset < frame.payload.length ? frame.payload[offset] : null,
        };
        if (values.length > 1) {
          changed.add(offset);
        }
      }
      result[entry.key] = IdentifierStatistics(
        identifier: entry.key,
        frameCount: frames.length,
        averagePeriodMicros: frames.length > 1
            ? periodSum / (frames.length - 1)
            : null,
        minimumPayloadLength: minLength,
        maximumPayloadLength: maxLength,
        changedByteOffsets: Set.unmodifiable(changed),
      );
    }
    return CaptureAnalysis(
      totalFrames: session.frames.length,
      identifiers: Map.unmodifiable(result),
    );
  }
}

class DifferentialResult {
  const DifferentialResult({
    required this.onlyInBaseline,
    required this.onlyInComparison,
    required this.changedIdentifiers,
  });
  final Set<int> onlyInBaseline;
  final Set<int> onlyInComparison;
  final Set<int> changedIdentifiers;
}

class DifferentialAnalyzer {
  const DifferentialAnalyzer();
  DifferentialResult compare(
    CaptureAnalysis baseline,
    CaptureAnalysis comparison,
  ) {
    final first = baseline.identifiers.keys.toSet();
    final second = comparison.identifiers.keys.toSet();
    final shared = first.intersection(second);
    final changed = <int>{
      for (final id in shared)
        if (_changed(baseline.identifiers[id]!, comparison.identifiers[id]!))
          id,
    };
    return DifferentialResult(
      onlyInBaseline: Set.unmodifiable(first.difference(second)),
      onlyInComparison: Set.unmodifiable(second.difference(first)),
      changedIdentifiers: Set.unmodifiable(changed),
    );
  }

  bool _changed(IdentifierStatistics a, IdentifierStatistics b) =>
      a.frameCount != b.frameCount ||
      a.minimumPayloadLength != b.minimumPayloadLength ||
      a.maximumPayloadLength != b.maximumPayloadLength ||
      !_setEquals(a.changedByteOffsets, b.changedByteOffsets);
  bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
