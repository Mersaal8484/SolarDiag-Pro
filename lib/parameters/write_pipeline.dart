import '../audit/audit_chain.dart';
import 'parameter_models.dart';
import 'parameter_validator.dart';

abstract interface class ParameterTransport {
  Future<num> readParameter(String id);
  Future<void> writeParameter(String id, num value);
}

class VerifiedWritePipeline {
  VerifiedWritePipeline({
    required this.transport,
    required this.audit,
    this.validator = const ParameterValidator(),
  });
  final ParameterTransport transport;
  final AuditChain audit;
  final ParameterValidator validator;

  Future<WriteResult> execute({
    required ParameterChange change,
    required ParameterSnapshot current,
    required AuthorizationTier authorization,
    required bool safetyAcknowledged,
    required bool simulatedSession,
  }) async {
    final validation = validator.validate(
      change: change,
      current: current,
      authorization: authorization,
      safetyAcknowledged: safetyAcknowledged,
      simulatedSession: simulatedSession,
    );
    final before = current.values[change.definition.id];
    if (!validation.isValid) {
      audit.append('parameter_write_rejected', {
        'parameter': change.definition.id,
        'requested': change.requestedValue,
        'issues': validation.issues.map((issue) => issue.code.name).join(','),
      });
      return WriteResult(
        outcome: WriteOutcome.rejected,
        validation: validation,
        before: before,
        requested: change.requestedValue,
        readback: null,
        auditHead: audit.head,
      );
    }
    if (before == null) {
      const missing = ValidationResult([
        ValidationIssue(
          ValidationCode.unmetDependency,
          'Current parameter value must be read before writing.',
        ),
      ]);
      audit.append('parameter_write_rejected', {
        'parameter': change.definition.id,
        'requested': change.requestedValue,
        'issues': 'missing_current_value',
      });
      return WriteResult(
        outcome: WriteOutcome.rejected,
        validation: missing,
        before: null,
        requested: change.requestedValue,
        readback: null,
        auditHead: audit.head,
      );
    }
    audit.append('parameter_write_started', {
      'parameter': change.definition.id,
      'before': before,
      'requested': change.requestedValue,
      'simulated': simulatedSession,
    });
    try {
      await transport.writeParameter(
        change.definition.id,
        change.requestedValue,
      );
      final readback = await transport.readParameter(change.definition.id);
      if (readback != change.requestedValue) {
        audit.append('parameter_readback_mismatch', {
          'parameter': change.definition.id,
          'requested': change.requestedValue,
          'readback': readback,
        });
        try {
          await transport.writeParameter(change.definition.id, before);
          final rollbackReadback = await transport.readParameter(
            change.definition.id,
          );
          final rolledBack = rollbackReadback == before;
          audit.append(
            rolledBack
                ? 'parameter_rollback_verified'
                : 'parameter_rollback_failed',
            {
              'parameter': change.definition.id,
              'expected': before,
              'readback': rollbackReadback,
            },
          );
          return WriteResult(
            outcome: rolledBack
                ? WriteOutcome.rolledBack
                : WriteOutcome.readbackMismatch,
            validation: validation,
            before: before,
            requested: change.requestedValue,
            readback: readback,
            auditHead: audit.head,
          );
        } catch (error) {
          audit.append('parameter_rollback_failed', {
            'parameter': change.definition.id,
            'error': error.runtimeType.toString(),
          });
          return WriteResult(
            outcome: WriteOutcome.readbackMismatch,
            validation: validation,
            before: before,
            requested: change.requestedValue,
            readback: readback,
            auditHead: audit.head,
          );
        }
      }
      audit.append('parameter_write_verified', {
        'parameter': change.definition.id,
        'before': before,
        'after': readback,
      });
      return WriteResult(
        outcome: WriteOutcome.applied,
        validation: validation,
        before: before,
        requested: change.requestedValue,
        readback: readback,
        auditHead: audit.head,
      );
    } catch (error) {
      audit.append('parameter_write_failed', {
        'parameter': change.definition.id,
        'error': error.runtimeType.toString(),
      });
      return WriteResult(
        outcome: WriteOutcome.transportFailed,
        validation: validation,
        before: before,
        requested: change.requestedValue,
        readback: null,
        auditHead: audit.head,
      );
    }
  }
}
