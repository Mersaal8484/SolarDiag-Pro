import 'dart:collection';
import 'dart:convert';

import 'capture_models.dart';
import 'findings.dart';

enum PayloadLengthMode { fixed, lengthField, variable }

enum TextEncodingKind { ascii, bcd, hexAscii }

class AddressFieldCandidate {
  const AddressFieldCandidate({
    required this.offset,
    required this.distinctValues,
    required this.confidence,
    required this.evidence,
  });

  final int offset;
  final Set<int> distinctValues;
  final double confidence;
  final String evidence;
}

class ResponseTimingAnalysis {
  const ResponseTimingAnalysis({
    required this.pairCount,
    required this.minimumNanos,
    required this.medianNanos,
    required this.percentile95Nanos,
    required this.maximumNanos,
    required this.derivedTimeoutNanos,
  });

  final int pairCount;
  final int minimumNanos;
  final int medianNanos;
  final int percentile95Nanos;
  final int maximumNanos;
  final int derivedTimeoutNanos;

  String get recommendationLabel => 'derived';
}

class PayloadLengthAnalysis {
  const PayloadLengthAnalysis({
    required this.mode,
    required this.fixedLength,
    required this.lengthFieldOffset,
    required this.lengthAdjustment,
    required this.confidence,
  });

  final PayloadLengthMode mode;
  final int? fixedLength;
  final int? lengthFieldOffset;
  final int? lengthAdjustment;
  final double confidence;
}

class DecodedTextCandidate {
  const DecodedTextCandidate({
    required this.kind,
    required this.sample,
    required this.matches,
    required this.eligibleFrames,
    required this.confidence,
  });

  final TextEncodingKind kind;
  final String sample;
  final int matches;
  final int eligibleFrames;
  final double confidence;
}

class NumericInterpretation {
  const NumericInterpretation({
    required this.identifier,
    required this.byteOffset,
    required this.littleEndian,
    required this.signed,
    required this.scale,
    required this.minimum,
    required this.maximum,
    required this.confidence,
    required this.evidence,
  });

  final int identifier;
  final int byteOffset;
  final bool littleEndian;
  final bool signed;
  final double scale;
  final double minimum;
  final double maximum;
  final double confidence;
  final String evidence;
}

class BitfieldCandidate {
  const BitfieldCandidate({
    required this.identifier,
    required this.bit,
    required this.toggleCount,
    required this.correlatedBit,
    required this.correlation,
    required this.confidence,
  });

  final int identifier;
  final int bit;
  final int toggleCount;
  final int? correlatedBit;
  final double correlation;
  final double confidence;
}

class CanSignalCandidate {
  const CanSignalCandidate({
    required this.identifier,
    required this.startBit,
    required this.length,
    required this.littleEndian,
    required this.confidence,
    required this.evidence,
  });

  final int identifier;
  final int startBit;
  final int length;
  final bool littleEndian;
  final double confidence;
  final String evidence;
}

class AdvancedInferenceReport {
  const AdvancedInferenceReport({
    required this.processedFrames,
    required this.addressFields,
    required this.responseTiming,
    required this.payloadLength,
    required this.textCandidates,
    required this.numericInterpretations,
    required this.bitfields,
    required this.canSignals,
    required this.findings,
    required this.estimatedPeakBytes,
  });

  final int processedFrames;
  final List<AddressFieldCandidate> addressFields;
  final ResponseTimingAnalysis? responseTiming;
  final PayloadLengthAnalysis payloadLength;
  final List<DecodedTextCandidate> textCandidates;
  final List<NumericInterpretation> numericInterpretations;
  final List<BitfieldCandidate> bitfields;
  final List<CanSignalCandidate> canSignals;
  final List<ProtocolFinding> findings;
  final int estimatedPeakBytes;
}

class AdvancedInferenceEngine {
  const AdvancedInferenceEngine({
    this.maximumIdentifiers = 256,
    this.maximumTrackedBytes = 64,
    this.maximumLatencySamples = 4096,
  });

  final int maximumIdentifiers;
  final int maximumTrackedBytes;
  final int maximumLatencySamples;

  AdvancedInferenceReport analyze(
    Iterable<CapturedFrame> frames, {
    required String captureId,
  }) {
    final address = <_ByteEvidence>[
      for (var index = 0; index < maximumTrackedBytes; index++) _ByteEvidence(),
    ];
    final lengthCounts = <int, int>{};
    final lengthMatches = <_LengthKey, int>{};
    final pending = <String, ListQueue<int>>{};
    final latencies = _BoundedValues(maximumLatencySamples);
    final identifiers = <int, _IdentifierInference>{};
    final text = {
      for (final kind in TextEncodingKind.values) kind: _TextEvidence(),
    };
    var processed = 0;

    for (final frame in frames) {
      processed++;
      final bytes = frame.rawBytes;
      lengthCounts.update(
        bytes.length,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final tracked = bytes.length < maximumTrackedBytes
          ? bytes.length
          : maximumTrackedBytes;
      final declaredAddresses = <int>{};
      for (final value in [frame.sourceAddress, frame.destinationAddress]) {
        final parsed = _parseAddress(value);
        if (parsed != null) {
          declaredAddresses.add(parsed);
        }
      }
      for (var offset = 0; offset < tracked; offset++) {
        address[offset].add(
          bytes[offset],
          metadataMatch: declaredAddresses.contains(bytes[offset]),
        );
        for (var adjustment = 0; adjustment <= 2; adjustment++) {
          if (bytes[offset] + adjustment == bytes.length) {
            final key = _LengthKey(offset, adjustment);
            lengthMatches.update(key, (value) => value + 1, ifAbsent: () => 1);
          }
        }
      }

      if (frame.direction == CaptureDirection.tx) {
        final queue = pending[frame.channel] ??= ListQueue<int>();
        if (queue.length == 32) {
          queue.removeFirst();
        }
        queue.addLast(frame.timestampNanos);
      } else if (frame.direction == CaptureDirection.rx) {
        final queue = pending[frame.channel];
        if (queue != null && queue.isNotEmpty) {
          final requestTimestamp = queue.removeFirst();
          if (frame.timestampNanos >= requestTimestamp) {
            latencies.add(frame.timestampNanos - requestTimestamp);
          }
        }
      }

      if (bytes.isNotEmpty) {
        _updateTextEvidence(text, bytes);
      }
      final identifier = frame.identifier;
      if (identifier != null) {
        var inference = identifiers[identifier];
        if (inference == null && identifiers.length < maximumIdentifiers) {
          inference = _IdentifierInference(identifier, maximumTrackedBytes);
          identifiers[identifier] = inference;
        }
        inference?.add(frame);
      }
    }

    final addressCandidates = _addressCandidates(address, processed);
    final timing = _timing(latencies);
    final payloadLength = _payloadLength(
      processed,
      lengthCounts,
      lengthMatches,
    );
    final textCandidates = _textCandidates(text);
    final numeric = <NumericInterpretation>[];
    final bitfields = <BitfieldCandidate>[];
    final canSignals = <CanSignalCandidate>[];
    for (final inference in identifiers.values) {
      numeric.addAll(inference.numericInterpretations());
      bitfields.addAll(inference.bitfieldCandidates());
      final signal = inference.canSignalCandidate();
      if (signal != null) {
        canSignals.add(signal);
      }
    }
    numeric.sort((a, b) => b.confidence.compareTo(a.confidence));
    bitfields.sort((a, b) => b.confidence.compareTo(a.confidence));
    canSignals.sort((a, b) => b.confidence.compareTo(a.confidence));
    final findings = _findings(
      captureId: captureId,
      addresses: addressCandidates,
      timing: timing,
      payloadLength: payloadLength,
      text: textCandidates,
      numeric: numeric,
      bitfields: bitfields,
      signals: canSignals,
    );
    final estimate =
        maximumTrackedBytes * 96 +
        identifiers.length * (512 + maximumTrackedBytes * 48) +
        maximumLatencySamples * 8;
    return AdvancedInferenceReport(
      processedFrames: processed,
      addressFields: List.unmodifiable(addressCandidates),
      responseTiming: timing,
      payloadLength: payloadLength,
      textCandidates: List.unmodifiable(textCandidates),
      numericInterpretations: List.unmodifiable(numeric.take(32)),
      bitfields: List.unmodifiable(bitfields.take(64)),
      canSignals: List.unmodifiable(canSignals.take(32)),
      findings: List.unmodifiable(findings),
      estimatedPeakBytes: estimate,
    );
  }

  List<AddressFieldCandidate> _addressCandidates(
    List<_ByteEvidence> evidence,
    int frames,
  ) {
    final result = <AddressFieldCandidate>[];
    if (frames == 0) {
      return result;
    }
    for (var offset = 0; offset < evidence.length; offset++) {
      final item = evidence[offset];
      if (item.observations == 0 ||
          item.values.isEmpty ||
          item.values.any((value) => value < 1 || value > 247)) {
        continue;
      }
      final metadataRatio = item.metadataMatches / item.observations;
      final boundedCardinality = item.values.length <= 16 ? .35 : 0.0;
      final confidence = (metadataRatio * .65 + boundedCardinality)
          .clamp(0.0, 1.0)
          .toDouble();
      if (confidence < .35) {
        continue;
      }
      result.add(
        AddressFieldCandidate(
          offset: offset,
          distinctValues: Set.unmodifiable(item.values),
          confidence: confidence,
          evidence:
              '${item.metadataMatches}/${item.observations} metadata matches; '
              '${item.values.length} distinct values',
        ),
      );
    }
    result.sort((a, b) => b.confidence.compareTo(a.confidence));
    return result;
  }

  ResponseTimingAnalysis? _timing(_BoundedValues latencies) {
    if (latencies.count == 0) {
      return null;
    }
    final sorted = latencies.values.toList()..sort();
    final median = _percentile(sorted, .5);
    final p95 = _percentile(sorted, .95);
    final margin = p95 ~/ 2 < 1000000 ? 1000000 : p95 ~/ 2;
    return ResponseTimingAnalysis(
      pairCount: latencies.count,
      minimumNanos: sorted.first,
      medianNanos: median,
      percentile95Nanos: p95,
      maximumNanos: sorted.last,
      derivedTimeoutNanos: p95 + margin,
    );
  }

  PayloadLengthAnalysis _payloadLength(
    int processed,
    Map<int, int> lengths,
    Map<_LengthKey, int> matches,
  ) {
    if (processed == 0) {
      return const PayloadLengthAnalysis(
        mode: PayloadLengthMode.variable,
        fixedLength: null,
        lengthFieldOffset: null,
        lengthAdjustment: null,
        confidence: 0,
      );
    }
    if (lengths.length == 1) {
      return PayloadLengthAnalysis(
        mode: PayloadLengthMode.fixed,
        fixedLength: lengths.keys.single,
        lengthFieldOffset: null,
        lengthAdjustment: null,
        confidence: 1,
      );
    }
    MapEntry<_LengthKey, int>? best;
    for (final entry in matches.entries) {
      if (best == null || entry.value > best.value) {
        best = entry;
      }
    }
    final confidence = (best?.value ?? 0) / processed;
    if (best != null && confidence >= .6) {
      return PayloadLengthAnalysis(
        mode: PayloadLengthMode.lengthField,
        fixedLength: null,
        lengthFieldOffset: best.key.offset,
        lengthAdjustment: best.key.adjustment,
        confidence: confidence,
      );
    }
    return PayloadLengthAnalysis(
      mode: PayloadLengthMode.variable,
      fixedLength: null,
      lengthFieldOffset: null,
      lengthAdjustment: null,
      confidence: lengths.values.reduce((a, b) => a > b ? a : b) / processed,
    );
  }

  List<DecodedTextCandidate> _textCandidates(
    Map<TextEncodingKind, _TextEvidence> evidence,
  ) => [
    for (final entry in evidence.entries)
      if (entry.value.matches > 0)
        DecodedTextCandidate(
          kind: entry.key,
          sample: entry.value.sample,
          matches: entry.value.matches,
          eligibleFrames: entry.value.eligible,
          confidence: entry.value.matches / entry.value.eligible,
        ),
  ]..sort((a, b) => b.confidence.compareTo(a.confidence));

  List<ProtocolFinding> _findings({
    required String captureId,
    required List<AddressFieldCandidate> addresses,
    required ResponseTimingAnalysis? timing,
    required PayloadLengthAnalysis payloadLength,
    required List<DecodedTextCandidate> text,
    required List<NumericInterpretation> numeric,
    required List<BitfieldCandidate> bitfields,
    required List<CanSignalCandidate> signals,
  }) => [
    if (addresses.isNotEmpty)
      _finding(
        captureId,
        'address-field',
        'Computed address-field candidate',
        addresses.first.evidence,
      ),
    if (timing != null)
      _finding(
        captureId,
        'response-timing',
        'Derived response timeout recommendation',
        'p95=${timing.percentile95Nanos}ns; '
            'derived timeout=${timing.derivedTimeoutNanos}ns',
        timing: true,
      ),
    _finding(
      captureId,
      'payload-length',
      'Computed payload-length interpretation',
      '${payloadLength.mode.name}; confidence=${payloadLength.confidence}',
    ),
    if (text.isNotEmpty)
      _finding(
        captureId,
        'text-decoding',
        'Computed text-decoding candidate',
        '${text.first.kind.name}: ${text.first.sample}',
      ),
    if (numeric.isNotEmpty)
      _finding(
        captureId,
        'numeric-interpretation',
        'Ranked numeric interpretation',
        numeric.first.evidence,
      ),
    if (bitfields.isNotEmpty)
      _finding(
        captureId,
        'bitfield',
        'Computed bit-toggle correlation',
        'bit ${bitfields.first.bit}; correlation='
            '${bitfields.first.correlation}',
      ),
    if (signals.isNotEmpty)
      _finding(
        captureId,
        'can-signal',
        'Computed CAN signal boundary candidate',
        signals.first.evidence,
      ),
  ];
}

class _ByteEvidence {
  final values = <int>{};
  int observations = 0;
  int metadataMatches = 0;

  void add(int value, {required bool metadataMatch}) {
    observations++;
    if (values.length < 256) {
      values.add(value);
    }
    if (metadataMatch) {
      metadataMatches++;
    }
  }
}

class _LengthKey {
  const _LengthKey(this.offset, this.adjustment);

  final int offset;
  final int adjustment;

  @override
  bool operator ==(Object other) =>
      other is _LengthKey &&
      other.offset == offset &&
      other.adjustment == adjustment;

  @override
  int get hashCode => Object.hash(offset, adjustment);
}

class _BoundedValues {
  _BoundedValues(this.capacity);

  final int capacity;
  final List<int> values = [];
  int count = 0;

  void add(int value) {
    count++;
    if (values.length < capacity) {
      values.add(value);
      return;
    }
    final slot = count % capacity;
    values[slot] = value;
  }
}

class _TextEvidence {
  int eligible = 0;
  int matches = 0;
  String sample = '';

  void add(String value) {
    eligible++;
    matches++;
    if (sample.isEmpty) {
      sample = value;
    }
  }

  void miss() => eligible++;
}

class _IdentifierInference {
  _IdentifierInference(this.identifier, this.maximumBytes);

  final int identifier;
  final int maximumBytes;
  final Map<int, _NumericWordStats> numeric = {};
  final List<int> toggleCounts = [];
  final Map<int, int> coToggles = {};
  List<int>? previous;
  int frames = 0;

  void add(CapturedFrame frame) {
    frames++;
    final tracked = frame.rawBytes.length < maximumBytes
        ? frame.rawBytes.length
        : maximumBytes;
    for (var offset = 0; offset + 1 < tracked && offset < 8; offset++) {
      (numeric[offset] ??= _NumericWordStats()).add(
        frame.rawBytes[offset],
        frame.rawBytes[offset + 1],
      );
    }
    final prior = previous;
    if (prior != null) {
      final bits = <int>[];
      final shared = prior.length < tracked ? prior.length : tracked;
      while (toggleCounts.length < tracked * 8) {
        toggleCounts.add(0);
      }
      for (var byte = 0; byte < shared; byte++) {
        final changed = prior[byte] ^ frame.rawBytes[byte];
        for (var bit = 0; bit < 8; bit++) {
          if ((changed & (1 << bit)) != 0) {
            final absoluteBit = byte * 8 + bit;
            toggleCounts[absoluteBit]++;
            bits.add(absoluteBit);
          }
        }
      }
      for (var left = 0; left < bits.length; left++) {
        for (var right = left + 1; right < bits.length; right++) {
          final key = bits[left] * 512 + bits[right];
          coToggles.update(key, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    previous = List<int>.of(frame.rawBytes.take(maximumBytes));
  }

  List<NumericInterpretation> numericInterpretations() {
    final result = <NumericInterpretation>[];
    for (final entry in numeric.entries) {
      for (final littleEndian in [false, true]) {
        for (final signed in [false, true]) {
          for (final scale in [1.0, .1, .01, .001]) {
            final bounds = entry.value.bounds(
              littleEndian: littleEndian,
              signed: signed,
              scale: scale,
            );
            final withinBatteryRange =
                bounds.minimum >= 40 && bounds.maximum <= 60;
            final overlapsBatteryRange =
                bounds.maximum >= 40 && bounds.minimum <= 60;
            final plausible = bounds.minimum >= -1000 && bounds.maximum <= 1000;
            final smoothSeries = bounds.maximumStep <= 5;
            final confidence = withinBatteryRange
                ? smoothSeries
                      ? .95
                      : .9
                : overlapsBatteryRange
                ? smoothSeries
                      ? .72
                      : .67
                : plausible
                ? smoothSeries
                      ? .32
                      : .27
                : .08;
            result.add(
              NumericInterpretation(
                identifier: identifier,
                byteOffset: entry.key,
                littleEndian: littleEndian,
                signed: signed,
                scale: scale,
                minimum: bounds.minimum,
                maximum: bounds.maximum,
                confidence: confidence,
                evidence:
                    '0x${identifier.toRadixString(16)} bytes '
                    '${entry.key}-${entry.key + 1}; '
                    '${littleEndian ? 'little' : 'big'}-endian; '
                    '${signed ? 'signed' : 'unsigned'}; scale=$scale; '
                    'range=${bounds.minimum}..${bounds.maximum}; '
                    'max time-series step=${bounds.maximumStep}; '
                    'physical check=40-60 V for 16S LiFePO4',
              ),
            );
          }
        }
      }
    }
    result.sort((a, b) => b.confidence.compareTo(a.confidence));
    return result.take(8).toList(growable: false);
  }

  List<BitfieldCandidate> bitfieldCandidates() {
    final result = <BitfieldCandidate>[];
    for (var bit = 0; bit < toggleCounts.length; bit++) {
      final toggles = toggleCounts[bit];
      if (toggles == 0) {
        continue;
      }
      int? partner;
      var bestCoToggles = 0;
      for (var other = 0; other < toggleCounts.length; other++) {
        if (other == bit) {
          continue;
        }
        final low = bit < other ? bit : other;
        final high = bit < other ? other : bit;
        final coToggle = coToggles[low * 512 + high] ?? 0;
        if (coToggle > bestCoToggles) {
          bestCoToggles = coToggle;
          partner = other;
        }
      }
      final correlation = partner == null
          ? 0.0
          : bestCoToggles /
                (toggles > toggleCounts[partner]
                    ? toggles
                    : toggleCounts[partner]);
      result.add(
        BitfieldCandidate(
          identifier: identifier,
          bit: bit,
          toggleCount: toggles,
          correlatedBit: partner,
          correlation: correlation,
          confidence:
              (toggles / (frames > 1 ? frames - 1 : 1) * .7 + correlation * .3)
                  .clamp(0.0, 1.0)
                  .toDouble(),
        ),
      );
    }
    return result;
  }

  CanSignalCandidate? canSignalCandidate() {
    final changed = <int>[
      for (var bit = 0; bit < toggleCounts.length; bit++)
        if (toggleCounts[bit] > 0) bit,
    ];
    if (changed.isEmpty) {
      return null;
    }
    final start = changed.reduce((a, b) => a < b ? a : b);
    final end = changed.reduce((a, b) => a > b ? a : b);
    final span = end - start + 1;
    final density = changed.length / span;
    return CanSignalCandidate(
      identifier: identifier,
      startBit: start,
      length: span,
      littleEndian: true,
      confidence: (density * .7 + (frames >= 4 ? .2 : 0.0))
          .clamp(0.0, .9)
          .toDouble(),
      evidence:
          '0x${identifier.toRadixString(16)} changed bits '
          '$start-$end across $frames frames; density=$density',
    );
  }
}

class _NumericWordStats {
  final values = <_WordValue>[];
  int count = 0;

  void add(int first, int second) {
    count++;
    if (values.length < 4096) {
      values.add(_WordValue(first, second));
    } else {
      values[count % values.length] = _WordValue(first, second);
    }
  }

  _NumericBounds bounds({
    required bool littleEndian,
    required bool signed,
    required double scale,
  }) {
    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    var maximumStep = 0.0;
    double? previous;
    for (final word in values) {
      var raw = littleEndian
          ? word.first | (word.second << 8)
          : (word.first << 8) | word.second;
      if (signed && (raw & 0x8000) != 0) {
        raw -= 0x10000;
      }
      final value = raw * scale;
      if (value < minimum) {
        minimum = value;
      }
      if (value > maximum) {
        maximum = value;
      }
      final prior = previous;
      if (prior != null) {
        final step = (value - prior).abs();
        if (step > maximumStep) {
          maximumStep = step;
        }
      }
      previous = value;
    }
    return _NumericBounds(minimum, maximum, maximumStep);
  }
}

class _WordValue {
  const _WordValue(this.first, this.second);

  final int first;
  final int second;
}

class _NumericBounds {
  const _NumericBounds(this.minimum, this.maximum, this.maximumStep);

  final double minimum;
  final double maximum;
  final double maximumStep;
}

void _updateTextEvidence(
  Map<TextEncodingKind, _TextEvidence> evidence,
  List<int> bytes,
) {
  final isAscii = bytes.every((value) => value >= 32 && value <= 126);
  if (isAscii) {
    evidence[TextEncodingKind.ascii]!.add(ascii.decode(bytes));
  } else {
    evidence[TextEncodingKind.ascii]!.miss();
  }

  final bcd = bytes.every((value) => (value >> 4) <= 9 && (value & 0x0f) <= 9);
  if (bcd) {
    evidence[TextEncodingKind.bcd]!.add(
      bytes
          .map(
            (value) =>
                '${(value >> 4).toRadixString(10)}${(value & 0x0f).toRadixString(10)}',
          )
          .join(),
    );
  } else {
    evidence[TextEncodingKind.bcd]!.miss();
  }

  final hexAscii =
      bytes.length.isEven &&
      bytes.every(
        (value) =>
            (value >= 48 && value <= 57) ||
            (value >= 65 && value <= 70) ||
            (value >= 97 && value <= 102),
      );
  if (hexAscii) {
    final text = ascii.decode(bytes);
    final decoded = <int>[
      for (var index = 0; index < text.length; index += 2)
        int.parse(text.substring(index, index + 2), radix: 16),
    ];
    evidence[TextEncodingKind.hexAscii]!.add(
      decoded.every((value) => value >= 32 && value <= 126)
          ? ascii.decode(decoded)
          : decoded.map((value) => value.toRadixString(16)).join(' '),
    );
  } else {
    evidence[TextEncodingKind.hexAscii]!.miss();
  }
}

int _percentile(List<int> sorted, double percentile) {
  final index = ((sorted.length - 1) * percentile).round();
  return sorted[index];
}

int? _parseAddress(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim().toLowerCase();
  if (normalized == 'master') {
    return null;
  }
  return normalized.startsWith('0x')
      ? int.tryParse(normalized.substring(2), radix: 16)
      : int.tryParse(normalized);
}

ProtocolFinding _finding(
  String captureId,
  String suffix,
  String title,
  String summary, {
  bool timing = false,
}) => ProtocolFinding.observation(
  id: '$captureId-$suffix',
  title: title,
  evidence: [
    FindingEvidence(
      kind: timing ? EvidenceKind.timingStatistic : EvidenceKind.captureFrame,
      reference: '$captureId:$suffix',
      summary: summary,
      captureId: captureId,
    ),
    if (timing)
      FindingEvidence(
        kind: EvidenceKind.captureFrame,
        reference: '$captureId:$suffix:frames',
        summary: 'Timing statistic derived from capture frames.',
        captureId: captureId,
      ),
  ],
);
