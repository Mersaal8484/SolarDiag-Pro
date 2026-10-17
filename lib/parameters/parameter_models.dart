enum AuthorizationTier {
  viewer,
  technician,
  qualifiedTechnician,
  approvalEngineer,
}

enum ParameterRiskTier { standard, advanced, safetyCritical }

class ParameterDependency {
  const ParameterDependency({
    required this.parameterId,
    required this.allowedValues,
  });
  final String parameterId;
  final Set<num> allowedValues;
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
    this.dependencies = const [],
  });
  final String id;
  final String unit;
  final num minimum;
  final num maximum;
  final num step;
  final ParameterRiskTier riskTier;
  final AuthorizationTier requiredAuthorization;
  final bool writeVerifiedOnHardware;
  final List<ParameterDependency> dependencies;
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

enum ValidationCode {
  valid,
  belowMinimum,
  aboveMaximum,
  invalidStep,
  unmetDependency,
  insufficientAuthorization,
  unverifiedWrite,
  acknowledgementRequired,
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

enum WriteOutcome {
  applied,
  rejected,
  transportFailed,
  readbackMismatch,
  rolledBack,
}

class WriteResult {
  const WriteResult({
    required this.outcome,
    required this.validation,
    required this.before,
    required this.requested,
    required this.readback,
    required this.auditHead,
  });
  final WriteOutcome outcome;
  final ValidationResult validation;
  final num? before;
  final num requested;
  final num? readback;
  final String auditHead;
}
