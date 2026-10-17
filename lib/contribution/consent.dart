class ContributionConsent {
  const ContributionConsent({
    required this.logs,
    required this.samples,
    required this.notes,
    required this.deviceIdentity,
    required this.grantedAt,
    required this.consentVersion,
    this.revokedAt,
  });
  final bool logs;
  final bool samples;
  final bool notes;
  final bool deviceIdentity;
  final DateTime grantedAt;
  final String consentVersion;
  final DateTime? revokedAt;
  bool get isValid =>
      revokedAt == null && (logs || samples || notes || deviceIdentity);
  ContributionConsent revoke(DateTime at) => ContributionConsent(
    logs: logs,
    samples: samples,
    notes: notes,
    deviceIdentity: deviceIdentity,
    grantedAt: grantedAt,
    consentVersion: consentVersion,
    revokedAt: at,
  );
}
