import '../audit/audit_chain.dart';

enum FindingState {
  observation,
  hypothesis,
  candidate,
  confirmed,
  verified,
  rejected,
}

enum EvidenceKind {
  captureFrame,
  timingStatistic,
  differential,
  documentReference,
  hardwareValidation,
}

enum FindingRole { analyst, approvalEngineer }

class FindingActor {
  const FindingActor({
    required this.id,
    required this.role,
    required this.authenticated,
  });
  final String id;
  final FindingRole role;
  final bool authenticated;
}

class FindingEvidence {
  const FindingEvidence({
    required this.kind,
    required this.reference,
    required this.summary,
    this.weight = 0,
    this.captureId,
    this.repeatedAba = false,
  });
  final EvidenceKind kind;
  final String reference;
  final String summary;
  final double weight;
  final String? captureId;
  final bool repeatedAba;
}

class FindingEvidenceRules {
  const FindingEvidenceRules({
    this.independentCaptureWeight = .12,
    this.repeatedAbaWeight = .18,
    this.hardwareValidationWeight = .35,
    this.unverifiedCap = .95,
  });

  final double independentCaptureWeight;
  final double repeatedAbaWeight;
  final double hardwareValidationWeight;
  final double unverifiedCap;

  double confidence(Iterable<FindingEvidence> evidence) {
    final items = evidence.toList();
    final captures = items
        .where((item) => item.kind == EvidenceKind.captureFrame)
        .map((item) => item.captureId ?? item.reference)
        .toSet();
    final documentWeight = items
        .where((item) => item.kind == EvidenceKind.documentReference)
        .fold<double>(0, (total, item) => total + item.weight.clamp(0, 1));
    final repeatedDifferentials = items.where(
      (item) => item.kind == EvidenceKind.differential && item.repeatedAba,
    );
    final hardwareRecords = items.where(
      (item) => item.kind == EvidenceKind.hardwareValidation,
    );
    final score =
        documentWeight +
        captures.length * independentCaptureWeight +
        repeatedDifferentials.length * repeatedAbaWeight +
        hardwareRecords.length * hardwareValidationWeight;
    final cap = hardwareRecords.isEmpty ? unverifiedCap : 1.0;
    return score.clamp(0, cap);
  }
}

class FindingPromotion {
  const FindingPromotion({
    required this.from,
    required this.to,
    required this.actorId,
    required this.role,
    required this.at,
    required this.auditHash,
  });
  final FindingState from;
  final FindingState to;
  final String actorId;
  final FindingRole role;
  final DateTime at;
  final String auditHash;
}

class ProtocolFinding {
  const ProtocolFinding._({
    required this.id,
    required this.title,
    required this.state,
    required this.confidence,
    required this.evidence,
    required this.promotions,
    required this.rules,
  });

  factory ProtocolFinding.observation({
    required String id,
    required String title,
    Iterable<FindingEvidence> evidence = const [],
    FindingEvidenceRules rules = const FindingEvidenceRules(),
  }) {
    final initialEvidence = List<FindingEvidence>.unmodifiable(evidence);
    return ProtocolFinding._(
      id: id,
      title: title,
      state: FindingState.observation,
      confidence: rules.confidence(initialEvidence),
      evidence: initialEvidence,
      promotions: const [],
      rules: rules,
    );
  }

  final String id;
  final String title;
  final FindingState state;
  final double confidence;
  final List<FindingEvidence> evidence;
  final List<FindingPromotion> promotions;
  final FindingEvidenceRules rules;

  ProtocolFinding advance(
    FindingState next, {
    required FindingEvidence newEvidence,
    required FindingActor actor,
    required DateTime at,
    required AuditChain audit,
  }) {
    _requireActor(actor);
    if (state == FindingState.rejected ||
        next == FindingState.rejected ||
        next.index != state.index + 1) {
      throw StateError(
        'Findings must advance exactly one review state at a time.',
      );
    }
    if (next == FindingState.verified &&
        (actor.role != FindingRole.approvalEngineer ||
            newEvidence.kind != EvidenceKind.hardwareValidation)) {
      throw StateError(
        'Verified state requires an approval engineer and hardware evidence.',
      );
    }
    final allEvidence = List<FindingEvidence>.unmodifiable([
      ...evidence,
      newEvidence,
    ]);
    final entry = audit.append('finding_promoted', {
      'finding_id': id,
      'from': state.name,
      'to': next.name,
      'actor_id': actor.id,
      'role': actor.role.name,
      'at': at.toUtc().toIso8601String(),
      'evidence': newEvidence.reference,
    });
    return ProtocolFinding._(
      id: id,
      title: title,
      state: next,
      confidence: rules.confidence(allEvidence),
      evidence: allEvidence,
      promotions: List.unmodifiable([
        ...promotions,
        FindingPromotion(
          from: state,
          to: next,
          actorId: actor.id,
          role: actor.role,
          at: at,
          auditHash: entry.hash,
        ),
      ]),
      rules: rules,
    );
  }

  ProtocolFinding reject({
    required FindingActor actor,
    required DateTime at,
    required String reason,
    required AuditChain audit,
  }) {
    _requireActor(actor);
    if (state == FindingState.verified ||
        state == FindingState.rejected ||
        reason.trim().isEmpty) {
      throw StateError('This finding cannot be rejected.');
    }
    final entry = audit.append('finding_rejected', {
      'finding_id': id,
      'from': state.name,
      'actor_id': actor.id,
      'role': actor.role.name,
      'at': at.toUtc().toIso8601String(),
      'reason': reason.trim(),
    });
    return ProtocolFinding._(
      id: id,
      title: title,
      state: FindingState.rejected,
      confidence: confidence,
      evidence: evidence,
      promotions: List.unmodifiable([
        ...promotions,
        FindingPromotion(
          from: state,
          to: FindingState.rejected,
          actorId: actor.id,
          role: actor.role,
          at: at,
          auditHash: entry.hash,
        ),
      ]),
      rules: rules,
    );
  }

  static void _requireActor(FindingActor actor) {
    if (!actor.authenticated || actor.id.trim().isEmpty) {
      throw StateError('An authenticated finding actor is required.');
    }
  }
}
