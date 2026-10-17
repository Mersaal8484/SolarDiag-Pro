import 'capture_analysis.dart';
import 'capture_models.dart';
import 'findings.dart';

class DifferentialFieldCandidate {
  const DifferentialFieldCandidate({
    required this.identifier,
    required this.byteOffset,
    required this.bitIndex,
    required this.score,
    required this.baselineValues,
    required this.comparisonValues,
    required this.evidence,
    required this.repeatedAba,
  });

  final int identifier;
  final int byteOffset;
  final int? bitIndex;
  final double score;
  final Set<int> baselineValues;
  final Set<int> comparisonValues;
  final List<String> evidence;
  final bool repeatedAba;
}

class SafeDifferentialReport {
  const SafeDifferentialReport({
    required this.summary,
    required this.candidates,
    required this.findings,
  });

  final DifferentialResult summary;
  final List<DifferentialFieldCandidate> candidates;
  final List<ProtocolFinding> findings;
}

class SafeDifferentialAnalyzer {
  const SafeDifferentialAnalyzer({this.maximumCandidates = 64});

  final int maximumCandidates;

  SafeDifferentialReport compare(
    CaptureSession baseline,
    CaptureSession comparison, {
    CaptureSession? baselineRepeat,
  }) {
    if (maximumCandidates <= 0) {
      throw ArgumentError.value(maximumCandidates, 'maximumCandidates');
    }
    final analyzer = const CaptureAnalyzer();
    final baseSummary = const DifferentialAnalyzer().compare(
      analyzer.analyze(baseline),
      analyzer.analyze(comparison),
    );
    final first = _valuesByField(baseline);
    final second = _valuesByField(comparison);
    final repeat = baselineRepeat == null
        ? const <_FieldKey, _FieldValues>{}
        : _valuesByField(baselineRepeat);
    final shared = first.keys.toSet().intersection(second.keys.toSet());
    final candidates = <DifferentialFieldCandidate>[];
    for (final key in shared) {
      final baselineValues = first[key]!;
      final comparisonValues = second[key]!;
      final byteScore = _distributionDistance(
        baselineValues.counts,
        comparisonValues.counts,
      );
      final repeatedAba =
          baselineRepeat != null &&
          repeat.containsKey(key) &&
          _distributionDistance(baselineValues.counts, repeat[key]!.counts) <=
              .05;
      if (byteScore > 0) {
        candidates.add(
          _candidate(
            key,
            baselineValues,
            comparisonValues,
            score: byteScore,
            repeatedAba: repeatedAba,
          ),
        );
      }
      for (var bit = 0; bit < 8; bit++) {
        final score =
            (_bitRatio(baselineValues, bit) - _bitRatio(comparisonValues, bit))
                .abs();
        if (score > 0) {
          candidates.add(
            _candidate(
              key,
              baselineValues,
              comparisonValues,
              bitIndex: bit,
              score: score,
              repeatedAba: repeatedAba,
            ),
          );
        }
      }
    }
    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      final byIdentifier = a.identifier.compareTo(b.identifier);
      if (byIdentifier != 0) {
        return byIdentifier;
      }
      final byOffset = a.byteOffset.compareTo(b.byteOffset);
      if (byOffset != 0) {
        return byOffset;
      }
      return (a.bitIndex ?? -1).compareTo(b.bitIndex ?? -1);
    });
    final limited = List<DifferentialFieldCandidate>.unmodifiable(
      candidates.take(maximumCandidates),
    );
    final summary = DifferentialResult(
      onlyInBaseline: baseSummary.onlyInBaseline,
      onlyInComparison: baseSummary.onlyInComparison,
      changedIdentifiers: Set.unmodifiable({
        ...baseSummary.changedIdentifiers,
        ...candidates.map((candidate) => candidate.identifier),
      }),
    );
    return SafeDifferentialReport(
      summary: summary,
      candidates: limited,
      findings: List.unmodifiable(
        limited
            .take(8)
            .map(
              (candidate) => _finding(
                candidate,
                baseline.id,
                comparison.id,
                baselineRepeat?.id,
              ),
            ),
      ),
    );
  }

  DifferentialFieldCandidate _candidate(
    _FieldKey key,
    _FieldValues baseline,
    _FieldValues comparison, {
    required double score,
    required bool repeatedAba,
    int? bitIndex,
  }) => DifferentialFieldCandidate(
    identifier: key.identifier,
    byteOffset: key.offset,
    bitIndex: bitIndex,
    score: score,
    baselineValues: Set.unmodifiable(baseline.counts.keys),
    comparisonValues: Set.unmodifiable(comparison.counts.keys),
    evidence: List.unmodifiable([
      ...baseline.references.take(3),
      ...comparison.references.take(3),
    ]),
    repeatedAba: repeatedAba,
  );

  ProtocolFinding _finding(
    DifferentialFieldCandidate candidate,
    String baselineId,
    String comparisonId,
    String? repeatId,
  ) {
    final field = candidate.bitIndex == null
        ? 'byte ${candidate.byteOffset}'
        : 'byte ${candidate.byteOffset}, bit ${candidate.bitIndex}';
    return ProtocolFinding.observation(
      id: 'diff-${candidate.identifier}-${candidate.byteOffset}-${candidate.bitIndex ?? "byte"}',
      title:
          'Differential candidate at 0x${candidate.identifier.toRadixString(16)} $field',
      evidence: [
        FindingEvidence(
          kind: EvidenceKind.differential,
          reference: repeatId == null
              ? '$baselineId->$comparisonId'
              : '$baselineId->$comparisonId->$repeatId',
          summary:
              'Observed distribution change; score ${candidate.score.toStringAsFixed(3)}.',
          repeatedAba: candidate.repeatedAba,
        ),
        ...candidate.evidence.map(
          (reference) => FindingEvidence(
            kind: EvidenceKind.captureFrame,
            reference: reference,
            summary: 'Source frame for differential candidate.',
            captureId: reference.split(':').first,
          ),
        ),
      ],
    );
  }

  Map<_FieldKey, _FieldValues> _valuesByField(CaptureSession session) {
    final result = <_FieldKey, _FieldValues>{};
    for (var frameIndex = 0; frameIndex < session.frames.length; frameIndex++) {
      final frame = session.frames[frameIndex];
      final identifier = frame.identifier;
      if (identifier == null) {
        continue;
      }
      for (var offset = 0; offset < frame.rawBytes.length; offset++) {
        final key = _FieldKey(identifier, offset);
        final values = result.putIfAbsent(key, _FieldValues.new);
        final value = frame.rawBytes[offset];
        values.counts[value] = (values.counts[value] ?? 0) + 1;
        values.total++;
        if (values.references.length < 3) {
          values.references.add('${session.id}:$frameIndex');
        }
      }
    }
    return result;
  }

  double _distributionDistance(Map<int, int> a, Map<int, int> b) {
    final aTotal = a.values.fold<int>(0, (sum, value) => sum + value);
    final bTotal = b.values.fold<int>(0, (sum, value) => sum + value);
    if (aTotal == 0 || bTotal == 0) {
      return 0;
    }
    final values = {...a.keys, ...b.keys};
    final difference = values.fold<double>(0, (sum, value) {
      final aRatio = (a[value] ?? 0) / aTotal;
      final bRatio = (b[value] ?? 0) / bTotal;
      return sum + (aRatio - bRatio).abs();
    });
    return difference / 2;
  }

  double _bitRatio(_FieldValues values, int bit) {
    if (values.total == 0) {
      return 0;
    }
    final setCount = values.counts.entries.fold<int>(
      0,
      (total, entry) =>
          total + (((entry.key >> bit) & 1) == 1 ? entry.value : 0),
    );
    return setCount / values.total;
  }
}

class _FieldKey {
  const _FieldKey(this.identifier, this.offset);

  final int identifier;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is _FieldKey &&
      other.identifier == identifier &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(identifier, offset);
}

class _FieldValues {
  final Map<int, int> counts = {};
  final List<String> references = [];
  int total = 0;
}
