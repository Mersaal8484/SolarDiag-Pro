import 'parameter_models.dart';

class ParameterValidator {
  const ParameterValidator();
  ValidationResult validate({
    required ParameterChange change,
    required ParameterSnapshot current,
    required AuthorizationTier authorization,
    required bool safetyAcknowledged,
    required bool simulatedSession,
  }) {
    final definition = change.definition;
    final value = change.requestedValue;
    final issues = <ValidationIssue>[];
    if (value < definition.minimum) {
      issues.add(
        const ValidationIssue(
          ValidationCode.belowMinimum,
          'Value is below the verified minimum.',
        ),
      );
    }
    if (value > definition.maximum) {
      issues.add(
        const ValidationIssue(
          ValidationCode.aboveMaximum,
          'Value is above the verified maximum.',
        ),
      );
    }
    final steps = (value - definition.minimum) / definition.step;
    if ((steps - steps.round()).abs() > 0.0000001) {
      issues.add(
        const ValidationIssue(
          ValidationCode.invalidStep,
          'Value does not align with the allowed step.',
        ),
      );
    }
    if (authorization.index < definition.requiredAuthorization.index) {
      issues.add(
        const ValidationIssue(
          ValidationCode.insufficientAuthorization,
          'The active identity tier cannot change this parameter.',
        ),
      );
    }
    if (!simulatedSession && !definition.writeVerifiedOnHardware) {
      issues.add(
        const ValidationIssue(
          ValidationCode.unverifiedWrite,
          'Write behavior is not verified on physical hardware.',
        ),
      );
    }
    if (definition.riskTier != ParameterRiskTier.standard &&
        !safetyAcknowledged) {
      issues.add(
        const ValidationIssue(
          ValidationCode.acknowledgementRequired,
          'Explicit safety acknowledgement is required.',
        ),
      );
    }
    for (final dependency in definition.dependencies) {
      final currentValue = current.values[dependency.parameterId];
      if (currentValue == null ||
          !dependency.allowedValues.contains(currentValue)) {
        issues.add(
          ValidationIssue(
            ValidationCode.unmetDependency,
            'Dependency ${dependency.parameterId} is not satisfied.',
          ),
        );
      }
    }
    return ValidationResult(List.unmodifiable(issues));
  }
}
