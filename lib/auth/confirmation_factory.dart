import '../parameters/parameter_models.dart';

/// Single authoritative factory for minting [ConfirmationToken] instances.
///
/// Under Round 4/5 safety architecture rules, UI components and pipelines must
/// never construct [ConfirmationToken] directly. They must use this factory,
/// which binds the token strictly to the displayed plan hash, device ID,
/// session ID, and expiration timestamp.
ConfirmationToken createConfirmationToken({
  required String shownPlanHash,
  required String deviceId,
  required String sessionId,
  required DateTime expiresAt,
}) {
  if (shownPlanHash.isEmpty) {
    throw ArgumentError.value(
      shownPlanHash,
      'shownPlanHash',
      'Plan hash cannot be empty.',
    );
  }
  if (deviceId.isEmpty) {
    throw ArgumentError.value(
      deviceId,
      'deviceId',
      'Device ID cannot be empty.',
    );
  }
  if (sessionId.isEmpty) {
    throw ArgumentError.value(
      sessionId,
      'sessionId',
      'Session ID cannot be empty.',
    );
  }
  return ConfirmationToken(
    diffHash: shownPlanHash,
    deviceId: deviceId,
    sessionId: sessionId,
    expiresAt: expiresAt,
  );
}
