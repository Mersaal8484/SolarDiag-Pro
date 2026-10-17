enum AuthorizationTier {
  viewer,
  technician,
  qualifiedTechnician,
  approvalEngineer,
}

enum ParameterRiskTier { standard, advanced, safetyCritical }

enum TransportKind { simulator, physical }

enum DeviceWriteState { known, unknownVerify }

class AuthorizationSession {
  const AuthorizationSession({required this.tier, required this.expiresAt});
  final AuthorizationTier tier;
  final DateTime expiresAt;
  bool isValidAt(DateTime time) => time.isBefore(expiresAt);
}

class ParameterCodec {
  const ParameterCodec({required this.scale, required this.step})
    : assert(scale > 0),
      assert(step > 0);
  final num scale;
  final num step;
  int encode(num value) => (value / scale).round();
  num decode(int raw) => raw * scale;
  bool sameRaw(num a, num b) => encode(a) == encode(b);
  bool isStepAligned(num value, num origin) {
    final rawStep = (step / scale).round();
    return rawStep > 0 && (encode(value) - encode(origin)) % rawStep == 0;
  }
}

class ParameterDependency {
  const ParameterDependency({
    required this.parameterId,
    required this.allowedValues,
  });
  final String parameterId;
  final Set<num> allowedValues;
}

enum ConstraintRelation { greaterThan, lessThanOrEqual }

class ParameterConstraint {
  const ParameterConstraint({
    required this.otherParameterId,
    required this.relation,
    this.multiplier = 1,
  });
  final String otherParameterId;
  final ConstraintRelation relation;
  final num multiplier;
}

class ParameterDefinition {
  const ParameterDefinition({
    required this.id,
    required this.unit,
    required this.minimum,
    required this.maximum,
    required this.step,
    required this.riskTier,
    required this.requiredAuthorization,
    required this.writeVerifiedOnHardware,
    this.scale,
    this.dependencies = const [],
    this.constraints = const [],
  });
  final String id;
  final String unit;
  final num minimum;
  final num maximum;
  final num step;
  final num? scale;
  final ParameterRiskTier riskTier;
  final AuthorizationTier requiredAuthorization;
  final bool writeVerifiedOnHardware;
  final List<ParameterDependency> dependencies;
  final List<ParameterConstraint> constraints;
  ParameterCodec get codec => ParameterCodec(scale: scale ?? step, step: step);
}

class ParameterSnapshot {
  ParameterSnapshot(Map<String, num> values, {required this.capturedAt})
    : values = Map.unmodifiable(values);
  final Map<String, num> values;
  final DateTime capturedAt;
}

class ParameterChange {
  const ParameterChange({
    required this.definition,
    required this.requestedValue,
  });
  final ParameterDefinition definition;
  final num requestedValue;
}

class DeviceWriteContext {
  const DeviceWriteContext({
    required this.deviceId,
    required this.sessionId,
    required this.profileModel,
    required this.profileFirmware,
    required this.connectedModel,
    required this.connectedFirmware,
    required this.linkHealthy,
    required this.writeLocked,
    required this.state,
  });
  final String deviceId;
  final String sessionId;
  final String profileModel;
  final String profileFirmware;
  final String connectedModel;
  final String connectedFirmware;
  final bool linkHealthy;
  final bool writeLocked;
  final DeviceWriteState state;
  bool get exactIdentityMatch =>
      profileModel == connectedModel && profileFirmware == connectedFirmware;
}

class DiffReview {
  const DiffReview({
    required this.parameterId,
    required this.before,
    required this.after,
    required this.risk,
    required this.consequenceEn,
    required this.consequenceAr,
    required this.hash,
  });
  final String parameterId;
  final num before;
  final num after;
  final ParameterRiskTier risk;
  final String consequenceEn;
  final String consequenceAr;
  final String hash;
}

class ConfirmationToken {
  ConfirmationToken({
    required this.diffHash,
    required this.deviceId,
    required this.sessionId,
    required this.expiresAt,
  });
  final String diffHash;
  final String deviceId;
  final String sessionId;
  final DateTime expiresAt;
  bool _used = false;
  bool consume({
    required String expectedHash,
    required DeviceWriteContext context,
    required DateTime now,
  }) {
    if (_used ||
        !now.isBefore(expiresAt) ||
        diffHash != expectedHash ||
        deviceId != context.deviceId ||
        sessionId != context.sessionId) {
      return false;
    }
    _used = true;
    return true;
  }
}

enum ValidationCode {
  belowMinimum,
  aboveMaximum,
  invalidStep,
  unmetDependency,
  crossParameterConstraint,
  insufficientAuthorization,
  expiredAuthorization,
  unverifiedWrite,
  acknowledgementRequired,
  identityMismatch,
  unhealthyLink,
  writeLocked,
  unknownDeviceState,
  invalidConfirmation,
}

class ValidationIssue {
  const ValidationIssue(this.code, this.message);
  final ValidationCode code;
  final String message;
}

class ValidationResult {
  const ValidationResult(this.issues);
  final List<ValidationIssue> issues;
  bool get isValid => issues.isEmpty;
}

enum WriteOutcome { applied, rejected, failed }

class RestorePlan {
  const RestorePlan({required this.snapshot, required this.reason});
  final ParameterSnapshot snapshot;
  final String reason;
}

class WriteResult {
  const WriteResult({
    required this.outcome,
    required this.validation,
    required this.before,
    required this.requested,
    required this.readback,
    required this.auditHead,
    required this.deviceState,
    this.restorePlan,
    this.diff,
  });
  final WriteOutcome outcome;
  final ValidationResult validation;
  final num? before;
  final num requested;
  final num? readback;
  final String auditHead;
  final DeviceWriteState deviceState;
  final RestorePlan? restorePlan;
  final DiffReview? diff;
}
