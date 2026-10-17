import '../protocol/device_profile.dart';

enum ReviewRole {
  contributor,
  system,
  analyst,
  approvalEngineer,
  administrator,
}

enum ContributionStage {
  draft,
  submitted,
  sanitized,
  triage,
  analysis,
  candidate,
  validation,
  safetyReview,
  approved,
  signed,
  published,
  declined,
  deprecated,
  revoked,
}

class AuthenticatedActor {
  const AuthenticatedActor({
    required this.id,
    required this.role,
    required this.authenticated,
  });

  final String id;
  final ReviewRole role;
  final bool authenticated;

  factory AuthenticatedActor.mock(String id, ReviewRole role) =>
      AuthenticatedActor(id: id, role: role, authenticated: true);
}

class ReviewRecord {
  const ReviewRecord({
    required this.stage,
    required this.actorId,
    required this.role,
    required this.at,
    this.reason,
  });

  final ContributionStage stage;
  final String actorId;
  final ReviewRole role;
  final DateTime at;
  final String? reason;
}

abstract interface class LifecycleHistoryStore {
  void appendLifecycleRecord(String contributionId, ReviewRecord record);
  List<ReviewRecord> loadLifecycleRecords(String contributionId);
}

class ContributionLifecycle {
  ContributionLifecycle({
    required this.contributionId,
    required DeviceProfile profile,
    required AuthenticatedActor contributor,
    required DateTime createdAt,
    this.historyStore,
  }) : hasWriteCapability = profile.hasWriteCapability,
       _records = [] {
    _requireIdentity(contributor);
    if (historyStore?.loadLifecycleRecords(contributionId).isNotEmpty ??
        false) {
      throw StateError('A lifecycle already exists for $contributionId.');
    }
    if (contributor.role != ReviewRole.contributor) {
      throw StateError('The creator must have the contributor role.');
    }
    _append(
      ReviewRecord(
        stage: ContributionStage.draft,
        actorId: contributor.id,
        role: contributor.role,
        at: createdAt,
      ),
    );
  }

  ContributionLifecycle._({
    required this.contributionId,
    required this.hasWriteCapability,
    required this._records,
    this.historyStore,
  });

  final String contributionId;
  final bool hasWriteCapability;
  final LifecycleHistoryStore? historyStore;
  final List<ReviewRecord> _records;

  List<ReviewRecord> get records => List.unmodifiable(_records);
  ContributionStage get stage => _records.last.stage;

  static ContributionLifecycle restore({
    required String contributionId,
    required DeviceProfile profile,
    required LifecycleHistoryStore historyStore,
  }) {
    final records = historyStore.loadLifecycleRecords(contributionId);
    if (records.isEmpty || records.first.stage != ContributionStage.draft) {
      throw StateError('Lifecycle history is missing its draft record.');
    }
    return ContributionLifecycle._(
      contributionId: contributionId,
      hasWriteCapability: profile.hasWriteCapability,
      records: List.of(records),
      historyStore: historyStore,
    );
  }

  static const _next = <ContributionStage, ContributionStage>{
    ContributionStage.draft: ContributionStage.submitted,
    ContributionStage.submitted: ContributionStage.sanitized,
    ContributionStage.sanitized: ContributionStage.triage,
    ContributionStage.triage: ContributionStage.analysis,
    ContributionStage.analysis: ContributionStage.candidate,
    ContributionStage.candidate: ContributionStage.validation,
    ContributionStage.validation: ContributionStage.safetyReview,
    ContributionStage.safetyReview: ContributionStage.approved,
    ContributionStage.approved: ContributionStage.signed,
    ContributionStage.signed: ContributionStage.published,
  };

  void advance({
    required ContributionStage to,
    required AuthenticatedActor actor,
    required DateTime at,
    String? reason,
  }) {
    _requireIdentity(actor);
    if (to == ContributionStage.declined) {
      _decline(actor, at, reason);
      return;
    }
    if (to == ContributionStage.deprecated || to == ContributionStage.revoked) {
      _retire(to, actor, at, reason);
      return;
    }

    var expected = _next[stage];
    if (!hasWriteCapability && stage == ContributionStage.validation) {
      expected = ContributionStage.approved;
    }
    if (to != expected) {
      throw StateError('Illegal lifecycle transition: $stage -> $to');
    }
    final requiredRole = switch (to) {
      ContributionStage.submitted => ReviewRole.contributor,
      ContributionStage.sanitized ||
      ContributionStage.triage => ReviewRole.system,
      ContributionStage.analysis ||
      ContributionStage.candidate => ReviewRole.analyst,
      ContributionStage.validation ||
      ContributionStage.safetyReview ||
      ContributionStage.approved => ReviewRole.approvalEngineer,
      ContributionStage.signed ||
      ContributionStage.published => ReviewRole.administrator,
      _ => throw StateError('Unsupported transition target: $to'),
    };
    if (actor.role != requiredRole) {
      throw StateError('$to requires the ${requiredRole.name} role.');
    }
    _ensureDistinctHumanActor(actor);
    _append(
      ReviewRecord(stage: to, actorId: actor.id, role: actor.role, at: at),
    );
  }

  void _decline(AuthenticatedActor actor, DateTime at, String? reason) {
    const preApproval = {
      ContributionStage.draft,
      ContributionStage.submitted,
      ContributionStage.sanitized,
      ContributionStage.triage,
      ContributionStage.analysis,
      ContributionStage.candidate,
      ContributionStage.validation,
      ContributionStage.safetyReview,
    };
    if (!preApproval.contains(stage) || actor.role == ReviewRole.system) {
      throw StateError('This contribution cannot be declined at $stage.');
    }
    if (reason == null || reason.trim().isEmpty) {
      throw StateError('Declining a contribution requires a reason.');
    }
    _ensureDistinctHumanActor(actor);
    _append(
      ReviewRecord(
        stage: ContributionStage.declined,
        actorId: actor.id,
        role: actor.role,
        at: at,
        reason: reason.trim(),
      ),
    );
  }

  void _retire(
    ContributionStage target,
    AuthenticatedActor actor,
    DateTime at,
    String? reason,
  ) {
    if (stage != ContributionStage.published ||
        actor.role != ReviewRole.administrator) {
      throw StateError(
        '$target requires an administrator and published state.',
      );
    }
    if (reason == null || reason.trim().isEmpty) {
      throw StateError('$target requires a reason.');
    }
    _ensureDistinctHumanActor(actor);
    _append(
      ReviewRecord(
        stage: target,
        actorId: actor.id,
        role: actor.role,
        at: at,
        reason: reason.trim(),
      ),
    );
  }

  void _ensureDistinctHumanActor(AuthenticatedActor actor) {
    if (actor.role == ReviewRole.system) {
      return;
    }
    for (final record in _records) {
      if (record.role != ReviewRole.system &&
          record.role != actor.role &&
          record.actorId == actor.id) {
        throw StateError('One person cannot serve in multiple review roles.');
      }
    }
  }

  static void _requireIdentity(AuthenticatedActor actor) {
    if (!actor.authenticated || actor.id.trim().isEmpty) {
      throw StateError('An authenticated actor identity is required.');
    }
  }

  void _append(ReviewRecord record) {
    _records.add(record);
    historyStore?.appendLifecycleRecord(contributionId, record);
  }
}
