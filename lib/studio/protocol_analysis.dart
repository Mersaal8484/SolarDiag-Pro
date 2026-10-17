import 'dart:math' as math;

import 'capture_models.dart';
import 'findings.dart';

enum BoundaryMode {
  idleGap,
  delimiter,
  lengthPrefix,
  fixedSize,
  asciiTerminator,
}

class BoundaryRule {
  const BoundaryRule._({
    required this.mode,
    this.idleGapNanos,
    this.delimiter = const [],
    this.lengthOffset = 0,
    this.lengthAdjustment = 0,
    this.fixedSize,
  });

  factory BoundaryRule.idleGap(int nanos) =>
      BoundaryRule._(mode: BoundaryMode.idleGap, idleGapNanos: nanos);
  factory BoundaryRule.delimiter(List<int> bytes) =>
      BoundaryRule._(mode: BoundaryMode.delimiter, delimiter: bytes);
  factory BoundaryRule.lengthPrefix({int offset = 0, int adjustment = 1}) =>
      BoundaryRule._(
        mode: BoundaryMode.lengthPrefix,
        lengthOffset: offset,
        lengthAdjustment: adjustment,
      );
  factory BoundaryRule.fixedSize(int size) =>
      BoundaryRule._(mode: BoundaryMode.fixedSize, fixedSize: size);
  factory BoundaryRule.asciiTerminator([List<int> bytes = const [13, 10]]) =>
      BoundaryRule._(mode: BoundaryMode.asciiTerminator, delimiter: bytes);

  final BoundaryMode mode;
  final int? idleGapNanos;
  final List<int> delimiter;
  final int lengthOffset;
  final int lengthAdjustment;
  final int? fixedSize;
}

class BoundaryDetectionResult {
  const BoundaryDetectionResult({
    required this.frames,
    required this.remainder,
  });
  final List<List<int>> frames;
  final List<int> remainder;
}

class FrameBoundaryDetector {
  const FrameBoundaryDetector();

  BoundaryDetectionResult detectBytes(List<int> bytes, BoundaryRule rule) {
    switch (rule.mode) {
      case BoundaryMode.fixedSize:
        final size = rule.fixedSize!;
        if (size <= 0) {
          throw ArgumentError.value(size, 'fixedSize');
        }
        final complete = bytes.length ~/ size;
        return BoundaryDetectionResult(
          frames: [
            for (var index = 0; index < complete; index++)
              List.unmodifiable(
                bytes.sublist(index * size, (index + 1) * size),
              ),
          ],
          remainder: List.unmodifiable(bytes.sublist(complete * size)),
        );
      case BoundaryMode.delimiter || BoundaryMode.asciiTerminator:
        return _byDelimiter(bytes, rule.delimiter);
      case BoundaryMode.lengthPrefix:
        return _byLength(bytes, rule);
      case BoundaryMode.idleGap:
        throw ArgumentError('Use detectTimedBytes for idle-gap framing.');
    }
  }

  BoundaryDetectionResult detectTimedBytes(
    List<(int, int)> timedBytes,
    BoundaryRule rule,
  ) {
    if (rule.mode != BoundaryMode.idleGap || rule.idleGapNanos == null) {
      throw ArgumentError('An idle-gap rule is required.');
    }
    final frames = <List<int>>[];
    var current = <int>[];
    int? previousTimestamp;
    for (final (timestamp, byte) in timedBytes) {
      if (previousTimestamp != null &&
          timestamp - previousTimestamp > rule.idleGapNanos! &&
          current.isNotEmpty) {
        frames.add(List.unmodifiable(current));
        current = <int>[];
      }
      current.add(byte);
      previousTimestamp = timestamp;
    }
    if (current.isNotEmpty) {
      frames.add(List.unmodifiable(current));
    }
    return BoundaryDetectionResult(
      frames: List.unmodifiable(frames),
      remainder: const [],
    );
  }

  BoundaryDetectionResult _byDelimiter(List<int> bytes, List<int> delimiter) {
    if (delimiter.isEmpty) {
      throw ArgumentError('Delimiter cannot be empty.');
    }
    final frames = <List<int>>[];
    var start = 0;
    for (var index = 0; index <= bytes.length - delimiter.length; index++) {
      var matches = true;
      for (var offset = 0; offset < delimiter.length; offset++) {
        if (bytes[index + offset] != delimiter[offset]) {
          matches = false;
        }
      }
      if (matches) {
        frames.add(
          List.unmodifiable(bytes.sublist(start, index + delimiter.length)),
        );
        start = index + delimiter.length;
        index = start - 1;
      }
    }
    return BoundaryDetectionResult(
      frames: List.unmodifiable(frames),
      remainder: List.unmodifiable(bytes.sublist(start)),
    );
  }

  BoundaryDetectionResult _byLength(List<int> bytes, BoundaryRule rule) {
    final frames = <List<int>>[];
    var cursor = 0;
    while (cursor + rule.lengthOffset < bytes.length) {
      final length = bytes[cursor + rule.lengthOffset] + rule.lengthAdjustment;
      if (length <= 0) {
        throw const FormatException('Invalid length prefix.');
      }
      if (cursor + length > bytes.length) {
        break;
      }
      frames.add(List.unmodifiable(bytes.sublist(cursor, cursor + length)));
      cursor += length;
    }
    return BoundaryDetectionResult(
      frames: List.unmodifiable(frames),
      remainder: List.unmodifiable(bytes.sublist(cursor)),
    );
  }
}

class RequestResponsePair {
  const RequestResponsePair({
    required this.requestIndex,
    required this.responseIndex,
    required this.latencyNanos,
  });
  final int requestIndex;
  final int responseIndex;
  final int latencyNanos;
}

class RequestResponseCorrelator {
  const RequestResponseCorrelator();
  List<RequestResponsePair> correlate(
    List<CapturedFrame> frames, {
    int maximumLatencyNanos = 1000000000,
  }) {
    final pairs = <RequestResponsePair>[];
    final pending = <int>[];
    for (var index = 0; index < frames.length; index++) {
      final frame = frames[index];
      if (frame.direction == CaptureDirection.tx) {
        pending.add(index);
      } else if (frame.direction == CaptureDirection.rx) {
        final candidate = pending.indexWhere((requestIndex) {
          final request = frames[requestIndex];
          return request.channel == frame.channel &&
              frame.timestampNanos >= request.timestampNanos &&
              frame.timestampNanos - request.timestampNanos <=
                  maximumLatencyNanos;
        });
        if (candidate >= 0) {
          final requestIndex = pending.removeAt(candidate);
          pairs.add(
            RequestResponsePair(
              requestIndex: requestIndex,
              responseIndex: index,
              latencyNanos:
                  frame.timestampNanos - frames[requestIndex].timestampNanos,
            ),
          );
        }
      }
    }
    return List.unmodifiable(pairs);
  }
}

enum ChecksumAlgorithm {
  sum8,
  xor8,
  lrc8,
  crc8,
  crc16Modbus,
  crc16CcittFalse,
  crc32IsoHdlc,
}

class ChecksumMatch {
  const ChecksumMatch({
    required this.algorithm,
    required this.checksumLength,
    required this.littleEndian,
    required this.dataStart,
    required this.dataEndExclusive,
  });
  final ChecksumAlgorithm algorithm;
  final int checksumLength;
  final bool littleEndian;
  final int dataStart;
  final int dataEndExclusive;
}

class ChecksumCatalog {
  const ChecksumCatalog();

  List<ChecksumMatch> findMatches(List<List<int>> frames) {
    if (frames.isEmpty) {
      return const [];
    }
    final matches = <ChecksumMatch>[];
    for (final algorithm in ChecksumAlgorithm.values) {
      final length = switch (algorithm) {
        ChecksumAlgorithm.sum8 ||
        ChecksumAlgorithm.xor8 ||
        ChecksumAlgorithm.lrc8 ||
        ChecksumAlgorithm.crc8 => 1,
        ChecksumAlgorithm.crc16Modbus || ChecksumAlgorithm.crc16CcittFalse => 2,
        ChecksumAlgorithm.crc32IsoHdlc => 4,
      };
      for (final littleEndian
          in length == 1 ? const [false] : const [false, true]) {
        if (frames.every(
          (frame) => _matches(frame, algorithm, length, littleEndian),
        )) {
          matches.add(
            ChecksumMatch(
              algorithm: algorithm,
              checksumLength: length,
              littleEndian: littleEndian,
              dataStart: 0,
              dataEndExclusive: frames.first.length - length,
            ),
          );
        }
      }
    }
    return List.unmodifiable(matches);
  }

  bool _matches(
    List<int> frame,
    ChecksumAlgorithm algorithm,
    int length,
    bool littleEndian,
  ) {
    if (frame.length <= length) {
      return false;
    }
    final data = frame.sublist(0, frame.length - length);
    final expected = _checksum(data, algorithm);
    var stored = 0;
    final checksum = frame.sublist(frame.length - length);
    final ordered = littleEndian ? checksum.reversed : checksum;
    for (final byte in ordered) {
      stored = (stored << 8) | byte;
    }
    final mask = length == 4 ? 0xffffffff : (1 << (length * 8)) - 1;
    return (expected & mask) == stored;
  }

  int _checksum(List<int> data, ChecksumAlgorithm algorithm) =>
      switch (algorithm) {
        ChecksumAlgorithm.sum8 => data.fold(
          0,
          (sum, byte) => (sum + byte) & 0xff,
        ),
        ChecksumAlgorithm.xor8 => data.fold(0, (value, byte) => value ^ byte),
        ChecksumAlgorithm.lrc8 =>
          (-data.fold<int>(0, (sum, byte) => sum + byte)) & 0xff,
        ChecksumAlgorithm.crc8 => _crc8(data),
        ChecksumAlgorithm.crc16Modbus => _crc16Modbus(data),
        ChecksumAlgorithm.crc16CcittFalse => _crc16Ccitt(data),
        ChecksumAlgorithm.crc32IsoHdlc => _crc32(data),
      };

  int _crc8(List<int> data) {
    var crc = 0;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 0x80) != 0
            ? ((crc << 1) ^ 0x07) & 0xff
            : (crc << 1) & 0xff;
      }
    }
    return crc;
  }

  int _crc16Modbus(List<int> data) {
    var crc = 0xffff;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xa001 : crc >> 1;
      }
    }
    return crc & 0xffff;
  }

  int _crc16Ccitt(List<int> data) {
    var crc = 0xffff;
    for (final byte in data) {
      crc ^= byte << 8;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 0x8000) != 0
            ? ((crc << 1) ^ 0x1021) & 0xffff
            : (crc << 1) & 0xffff;
      }
    }
    return crc;
  }

  int _crc32(List<int> data) {
    var crc = 0xffffffff;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

class PollingPattern {
  const PollingPattern({
    required this.fingerprint,
    required this.count,
    required this.averagePeriodNanos,
    required this.jitterNanos,
  });
  final String fingerprint;
  final int count;
  final double averagePeriodNanos;
  final double jitterNanos;
}

class PollingDetector {
  const PollingDetector();
  List<PollingPattern> detect(List<CapturedFrame> frames) {
    final groups = <String, List<CapturedFrame>>{};
    for (final frame in frames.where(
      (item) => item.direction == CaptureDirection.tx,
    )) {
      final fingerprint = '${frame.channel}:${frame.rawBytes.join(',')}';
      (groups[fingerprint] ??= []).add(frame);
    }
    return [
      for (final entry in groups.entries)
        if (entry.value.length >= 3) _pattern(entry.key, entry.value),
    ];
  }

  PollingPattern _pattern(String fingerprint, List<CapturedFrame> frames) {
    frames.sort((a, b) => a.timestampNanos.compareTo(b.timestampNanos));
    final intervals = [
      for (var index = 1; index < frames.length; index++)
        frames[index].timestampNanos - frames[index - 1].timestampNanos,
    ];
    final average = intervals.reduce((a, b) => a + b) / intervals.length;
    final jitter = math.sqrt(
      intervals
              .map((value) => math.pow(value - average, 2))
              .reduce((a, b) => a + b) /
          intervals.length,
    );
    return PollingPattern(
      fingerprint: fingerprint,
      count: frames.length,
      averagePeriodNanos: average,
      jitterNanos: jitter,
    );
  }
}

class ModbusClassification {
  const ModbusClassification({
    required this.address,
    required this.functionCode,
    required this.isException,
    required this.writeRisk,
  });
  final int address;
  final int functionCode;
  final bool isException;
  final bool writeRisk;
}

class ModbusClassifier {
  const ModbusClassifier();
  static const _writeFunctions = {5, 6, 15, 16, 22, 23};
  ModbusClassification? classify(List<int> frame) {
    if (frame.length < 2) {
      return null;
    }
    final rawFunction = frame[1];
    final function = rawFunction & 0x7f;
    return ModbusClassification(
      address: frame[0],
      functionCode: function,
      isException: (rawFunction & 0x80) != 0,
      writeRisk: _writeFunctions.contains(function),
    );
  }
}

class FrameCluster {
  const FrameCluster({
    required this.fingerprint,
    required this.frameIndices,
    required this.changedByteOffsets,
  });

  final String fingerprint;
  final List<int> frameIndices;
  final Set<int> changedByteOffsets;
}

class FrameClusterer {
  const FrameClusterer();

  List<FrameCluster> cluster(List<CapturedFrame> frames) {
    final groups = <String, List<int>>{};
    for (var index = 0; index < frames.length; index++) {
      final frame = frames[index];
      final protocolPrefix = frame.identifier == null
          ? frame.rawBytes.take(2).join(',')
          : 'can:${frame.identifier}';
      final fingerprint =
          '${frame.channel}|${frame.direction.name}|$protocolPrefix|${frame.rawBytes.length}';
      (groups[fingerprint] ??= []).add(index);
    }
    return List.unmodifiable(
      groups.entries.map((entry) {
        final changed = <int>{};
        final length = frames[entry.value.first].rawBytes.length;
        for (var offset = 0; offset < length; offset++) {
          final values = {
            for (final index in entry.value) frames[index].rawBytes[offset],
          };
          if (values.length > 1) {
            changed.add(offset);
          }
        }
        return FrameCluster(
          fingerprint: entry.key,
          frameIndices: List.unmodifiable(entry.value),
          changedByteOffsets: Set.unmodifiable(changed),
        );
      }),
    );
  }
}

class ProtocolAnalysisReport {
  const ProtocolAnalysisReport({
    required this.pairs,
    required this.pollingPatterns,
    required this.modbusFrames,
    required this.clusters,
    required this.findings,
  });
  final List<RequestResponsePair> pairs;
  final List<PollingPattern> pollingPatterns;
  final List<ModbusClassification> modbusFrames;
  final List<FrameCluster> clusters;
  final List<ProtocolFinding> findings;
}

class ProtocolAnalysisEngine {
  const ProtocolAnalysisEngine();
  ProtocolAnalysisReport analyze(CaptureSession session) {
    final pairs = const RequestResponseCorrelator().correlate(session.frames);
    final polling = const PollingDetector().detect(session.frames);
    final clusters = const FrameClusterer().cluster(session.frames);
    final modbus = <ModbusClassification>[];
    for (final frame in session.frames) {
      if (frame.protocolHint?.toLowerCase().contains('modbus') ?? false) {
        final classification = const ModbusClassifier().classify(
          frame.rawBytes,
        );
        if (classification != null) {
          modbus.add(classification);
        }
      }
    }
    final findings = <ProtocolFinding>[
      if (pairs.isNotEmpty)
        ProtocolFinding.observation(
          id: '${session.id}-request-response',
          title: 'Request/response timing relationship',
          evidence: [
            FindingEvidence(
              kind: EvidenceKind.timingStatistic,
              reference:
                  '${session.id}:frames:${pairs.first.requestIndex}-${pairs.first.responseIndex}',
              summary: '${pairs.length} request/response pairs correlated',
            ),
          ],
        ),
      if (polling.isNotEmpty)
        ProtocolFinding.observation(
          id: '${session.id}-polling',
          title: 'Repeated polling command',
          evidence: [
            FindingEvidence(
              kind: EvidenceKind.timingStatistic,
              reference: '${session.id}:polling:0',
              summary: '${polling.first.count} repeated requests',
            ),
          ],
        ),
      if (modbus.any((item) => item.writeRisk))
        ProtocolFinding.observation(
          id: '${session.id}-modbus-write-risk',
          title: 'Modbus write-function traffic observed',
          evidence: [
            FindingEvidence(
              kind: EvidenceKind.captureFrame,
              reference: '${session.id}:modbus-write',
              summary: 'Write function classified; replay remains prohibited',
              captureId: session.id,
            ),
          ],
        ),
    ];
    return ProtocolAnalysisReport(
      pairs: pairs,
      pollingPatterns: polling,
      modbusFrames: List.unmodifiable(modbus),
      clusters: clusters,
      findings: List.unmodifiable(findings),
    );
  }
}
