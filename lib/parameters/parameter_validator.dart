import 'parameter_models.dart';

class ParameterValidator {
  const ParameterValidator();
  ValidationResult validate({
    required ParameterChange change,
    required ParameterSnapshot current,
    required AuthorizationSession authorization,
    required bool safetyAcknowledged,
    required TransportKind transportKind,
    required DeviceWriteContext context,
    required DateTime now,
  }) {
    final d = change.definition;
    final value = change.requestedValue;
    final issues = <ValidationIssue>[];
    void add(ValidationCode code, String message) =>
        issues.add(ValidationIssue(code, message));
    if (!context.exactIdentityMatch) {
      add(
        ValidationCode.identityMismatch,
        'Exact model and firmware do not match.',
      );
    }
    if (!context.linkHealthy) {
      add(ValidationCode.unhealthyLink, 'The device link is not healthy.');
    }
    if (context.writeLocked) {
      add(ValidationCode.writeLocked, 'The device write lock is active.');
    }
    if (context.state == DeviceWriteState.unknownVerify) {
      add(
        ValidationCode.unknownDeviceState,
        'Device state is unknown and must be verified.',
      );
    }
    if (value < d.minimum) {
      add(ValidationCode.belowMinimum, 'Value is below the verified minimum.');
    }
    if (value > d.maximum) {
      add(ValidationCode.aboveMaximum, 'Value is above the verified maximum.');
    }
    if (!d.codec.isStepAligned(value, d.minimum)) {
      add(
        ValidationCode.invalidStep,
        'Value does not align with the allowed step.',
      );
    }
    if (!authorization.isValidAt(now)) {
      add(ValidationCode.expiredAuthorization, 'Authorization has expired.');
    }
    if (authorization.tier.index < d.requiredAuthorization.index) {
      add(
        ValidationCode.insufficientAuthorization,
        'The active identity tier cannot change this parameter.',
      );
    }
    if (transportKind == TransportKind.physical && !d.writeVerifiedOnHardware) {
      add(
        ValidationCode.unverifiedWrite,
        'Write behavior is not verified on physical hardware.',
      );
    }
    if (d.riskTier != ParameterRiskTier.standard && !safetyAcknowledged) {
      add(
        ValidationCode.acknowledgementRequired,
        'Explicit safety acknowledgement is required.',
      );
    }
    for (final dependency in d.dependencies) {
      final currentValue = current.values[dependency.parameterId];
      if (currentValue == null ||
          !dependency.allowedValues.contains(currentValue)) {
        add(
          ValidationCode.unmetDependency,
          'Dependency ${dependency.parameterId} is not satisfied.',
        );
      }
    }
    for (final constraint in d.constraints) {
      final other = current.values[constraint.otherParameterId];
      final limit = other == null ? null : other * constraint.multiplier;
      final satisfied =
          limit != null &&
          switch (constraint.relation) {
            ConstraintRelation.greaterThan => value > limit,
            ConstraintRelation.lessThanOrEqual => value <= limit,
          };
      if (!satisfied) {
        add(
          ValidationCode.crossParameterConstraint,
          'Cross-parameter constraint against ${constraint.otherParameterId} is not satisfied.',
        );
      }
    }
    return ValidationResult(List.unmodifiable(issues));
  }
}
