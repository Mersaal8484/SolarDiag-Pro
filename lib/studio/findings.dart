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

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'state': state.name,
    'confidence': confidence,
    'evidence': [
      for (final item in evidence)
        {
          'kind': item.kind.name,
          'reference': item.reference,
          'summary': item.summary,
          'weight': item.weight,
          'capture_id': item.captureId,
          'repeated_aba': item.repeatedAba,
        },
    ],
    'promotions': [
      for (final item in promotions)
        {
          'from': item.from.name,
          'to': item.to.name,
          'actor_id': item.actorId,
          'role': item.role.name,
          'at': item.at.toUtc().toIso8601String(),
          'audit_hash': item.auditHash,
        },
    ],
    'rules': {
      'independent_capture_weight': rules.independentCaptureWeight,
      'repeated_aba_weight': rules.repeatedAbaWeight,
      'hardware_validation_weight': rules.hardwareValidationWeight,
      'unverified_cap': rules.unverifiedCap,
    },
  };

  factory ProtocolFinding.fromJson(Map<String, Object?> json) {
    final evidenceJson = json['evidence'];
    final promotionsJson = json['promotions'];
    final rulesJson = json['rules'];
    if (evidenceJson is! List ||
        promotionsJson is! List ||
        rulesJson is! Map<String, Object?>) {
      throw const FormatException('Invalid finding document.');
    }
    final rules = FindingEvidenceRules(
      independentCaptureWeight: _number(
        rulesJson,
        'independent_capture_weight',
      ),
      repeatedAbaWeight: _number(rulesJson, 'repeated_aba_weight'),
      hardwareValidationWeight: _number(
        rulesJson,
        'hardware_validation_weight',
      ),
      unverifiedCap: _number(rulesJson, 'unverified_cap'),
    );
    final evidence = evidenceJson
        .map((raw) {
          if (raw is! Map<String, Object?>) {
            throw const FormatException('Invalid finding evidence.');
          }
          return FindingEvidence(
            kind: EvidenceKind.values.byName(_string(raw, 'kind')),
            reference: _string(raw, 'reference'),
            summary: _string(raw, 'summary'),
            weight: _number(raw, 'weight'),
            captureId: raw['capture_id'] as String?,
            repeatedAba: raw['repeated_aba'] as bool? ?? false,
          );
        })
        .toList(growable: false);
    final promotions = promotionsJson
        .map((raw) {
          if (raw is! Map<String, Object?>) {
            throw const FormatException('Invalid finding promotion.');
          }
          return FindingPromotion(
            from: FindingState.values.byName(_string(raw, 'from')),
            to: FindingState.values.byName(_string(raw, 'to')),
            actorId: _string(raw, 'actor_id'),
            role: FindingRole.values.byName(_string(raw, 'role')),
            at: DateTime.parse(_string(raw, 'at')),
            auditHash: _string(raw, 'audit_hash'),
          );
        })
        .toList(growable: false);
    return ProtocolFinding._(
      id: _string(json, 'id'),
      title: _string(json, 'title'),
      state: FindingState.values.byName(_string(json, 'state')),
      confidence: _number(json, 'confidence'),
      evidence: List.unmodifiable(evidence),
      promotions: List.unmodifiable(promotions),
      rules: rules,
    );
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Finding field $key must be a string.');
    }
    return value;
  }

  static double _number(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('Finding field $key must be numeric.');
    }
    return value.toDouble();
  }

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
