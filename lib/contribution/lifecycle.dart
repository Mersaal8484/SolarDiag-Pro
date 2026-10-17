enum ReviewRole { contributor, analyst, approvalEngineer, administrator }

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

class ReviewRecord {
  const ReviewRecord({
    required this.stage,
    required this.actorId,
    required this.role,
    required this.at,
  });
  final ContributionStage stage;
  final String actorId;
  final ReviewRole role;
  final DateTime at;
}

class ContributionLifecycle {
  ContributionLifecycle({required this.hasWriteCapability})
    : _records = [
        ReviewRecord(
          stage: ContributionStage.draft,
          actorId: 'creator',
          role: ReviewRole.contributor,
          at: DateTime.now(),
        ),
      ];
  final bool hasWriteCapability;
  final List<ReviewRecord> _records;
  List<ReviewRecord> get records => List.unmodifiable(_records);
  ContributionStage get stage => _records.last.stage;
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
    required String actorId,
    required ReviewRole role,
    required DateTime at,
  }) {
    var expected = _next[stage];
    if (!hasWriteCapability && stage == ContributionStage.validation) {
      expected = ContributionStage.approved;
    }
    if (to != expected) {
      throw StateError('Illegal lifecycle transition: $stage -> $to');
    }
    if ((to == ContributionStage.analysis ||
            to == ContributionStage.candidate) &&
        role != ReviewRole.analyst) {
      throw StateError('Analysis requires analyst role.');
    }
    if ((to == ContributionStage.validation ||
            to == ContributionStage.safetyReview ||
            to == ContributionStage.approved) &&
        role != ReviewRole.approvalEngineer) {
      throw StateError(
        'Validation and safety review require approval engineer role.',
      );
    }
    if ((to == ContributionStage.signed || to == ContributionStage.published) &&
        role != ReviewRole.administrator) {
      throw StateError('Signing and publishing require administrator role.');
    }
    if (to == ContributionStage.safetyReview) {
      final analyst = _records.lastWhere(
        (record) => record.role == ReviewRole.analyst,
        orElse: () => throw StateError('Analyst record is required.'),
      );
      if (analyst.actorId == actorId) {
        throw StateError('Approval engineer must differ from analyst.');
      }
    }
    _records.add(ReviewRecord(stage: to, actorId: actorId, role: role, at: at));
  }
}
