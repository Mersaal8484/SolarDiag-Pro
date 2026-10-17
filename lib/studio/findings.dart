enum FindingState { observation, hypothesis, candidate, confirmed, verified }

enum EvidenceKind {
  captureFrame,
  timingStatistic,
  differential,
  documentReference,
  hardwareValidation,
}

class FindingEvidence {
  const FindingEvidence({
    required this.kind,
    required this.reference,
    required this.summary,
  });
  final EvidenceKind kind;
  final String reference;
  final String summary;
}

class ProtocolFinding {
  const ProtocolFinding({
    required this.id,
    required this.title,
    required this.state,
    required this.confidence,
    required this.evidence,
  });
  final String id;
  final String title;
  final FindingState state;
  final double confidence;
  final List<FindingEvidence> evidence;

  ProtocolFinding advance(
    FindingState next, {
    required FindingEvidence newEvidence,
  }) {
    if (next.index != state.index + 1) {
      throw StateError(
        'Findings must advance exactly one review state at a time.',
      );
    }
    if (next == FindingState.verified &&
        newEvidence.kind != EvidenceKind.hardwareValidation) {
      throw StateError('Verified state requires hardware-validation evidence.');
    }
    return ProtocolFinding(
      id: id,
      title: title,
      state: next,
      confidence: _confidence([...evidence, newEvidence], next),
      evidence: List.unmodifiable([...evidence, newEvidence]),
    );
  }

  static double _confidence(
    List<FindingEvidence> evidence,
    FindingState state,
  ) {
    final diversity = evidence.map((item) => item.kind).toSet().length;
    final raw = .2 + evidence.length * .1 + diversity * .08 + state.index * .08;
    return raw.clamp(0, 1);
  }
}
