import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../audit/audit_chain.dart';
import 'parameter_models.dart';
import 'parameter_validator.dart';

part '../simulator/simulated_parameter_transport.dart';

typedef ParameterReader = Future<num> Function(String id);
typedef ConfigurationReader = Future<Map<String, num>> Function();
typedef ParameterWriter =
    Future<void> Function(String id, int rawValue, String idempotencyKey);

sealed class ParameterTransport {
  ParameterTransport._({
    required this.kind,
    required this._read,
    required this._readAll,
    required this._write,
  });
  factory ParameterTransport.physical({
    required ParameterReader read,
    required ConfigurationReader readAll,
    required ParameterWriter write,
  }) = _PhysicalParameterTransport;
  factory ParameterTransport._simulator({
    required ParameterReader read,
    required ConfigurationReader readAll,
    required ParameterWriter write,
  }) = _SimulatorParameterTransport;
  final TransportKind kind;
  final ParameterReader _read;
  final ConfigurationReader _readAll;
  final ParameterWriter _write;
  Future<num> readParameter(String id) => _read(id);
  Future<Map<String, num>> readConfiguration() => _readAll();
  Future<void> _commit(String id, int raw, String key) => _write(id, raw, key);
}

final class _PhysicalParameterTransport extends ParameterTransport {
  _PhysicalParameterTransport({
    required super.read,
    required super.readAll,
    required super.write,
  }) : super._(kind: TransportKind.physical);
}

final class _SimulatorParameterTransport extends ParameterTransport {
  _SimulatorParameterTransport({
    required super.read,
    required super.readAll,
    required super.write,
  }) : super._(kind: TransportKind.simulator);
}

class VerifiedWritePipeline {
  VerifiedWritePipeline({
    required this.transport,
    required this.audit,
    this.validator = const ParameterValidator(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final ParameterTransport transport;
  final AuditChain audit;
  final ParameterValidator validator;
  final DateTime Function() _clock;
  final Set<String> _completedKeys = {};
  Future<void> _serial = Future.value();

  Future<WriteResult> execute({
    required ParameterChange change,
    required AuthorizationSession authorization,
    required bool safetyAcknowledged,
    required DeviceWriteContext context,
    required ConfirmationToken confirmation,
    ConfirmationToken? secondConfirmation,
    required String idempotencyKey,
  }) {
    final result = Completer<WriteResult>();
    _serial = _serial.then((_) async {
      try {
        result.complete(
          await _execute(
            change,
            authorization,
            safetyAcknowledged,
            context,
            confirmation,
            secondConfirmation,
            idempotencyKey,
          ),
        );
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<WriteResult> _execute(
    ParameterChange change,
    AuthorizationSession authorization,
    bool acknowledged,
    DeviceWriteContext context,
    ConfirmationToken confirmation,
    ConfirmationToken? secondConfirmation,
    String key,
  ) async {
    final now = _clock().toUtc();
    if (audit.availability != AuditAvailability.available) {
      return _result(
        WriteOutcome.rejected,
        const ValidationResult([
          ValidationIssue(
            ValidationCode.auditKeyUnavailable,
            'Audit key unavailable; write operation is locked.',
          ),
        ]),
        null,
        change,
        null,
        context.state,
        null,
        null,
      );
    }
    audit.append('write_preflight', {
      'parameter': change.definition.id,
      'transport': transport.kind.name,
    });
    final values = await transport.readConfiguration();
    final snapshot = ParameterSnapshot(values, capturedAt: now);
    audit.append('write_snapshot', {'count': values.length});
    final validation = validator.validate(
      change: change,
      current: snapshot,
      authorization: authorization,
      safetyAcknowledged: acknowledged,
      transportKind: transport.kind,
      context: context,
      now: now,
    );
    audit.append('write_validate', {
      'valid': validation.isValid,
      'issues': validation.issues.map((e) => e.code.name).join(','),
    });
    final before = values[change.definition.id];
    if (!validation.isValid || before == null || _completedKeys.contains(key)) {
      audit.append('write_rejected', {
        'parameter': change.definition.id,
        'duplicate': _completedKeys.contains(key),
        'missing_before': before == null,
      });
      return _result(
        WriteOutcome.rejected,
        validation,
        before,
        change,
        null,
        context.state,
        null,
        null,
      );
    }
    final diff = _diff(change, before, context);
    audit.append('write_preview', {'diff_hash': diff.hash});
    final first = confirmation.consume(
      expectedHash: diff.hash,
      context: context,
      now: now,
    );
    final needsSecond =
        change.definition.riskTier == ParameterRiskTier.safetyCritical;
    final second =
        !needsSecond ||
        (secondConfirmation?.consume(
              expectedHash: diff.hash,
              context: context,
              now: now,
            ) ??
            false);
    audit.append('write_confirm', {'accepted': first && second});
    if (!first || !second) {
      audit.append('write_rejected', {
        'parameter': change.definition.id,
        'reason': 'invalid_confirmation',
      });
      const invalid = ValidationResult([
        ValidationIssue(
          ValidationCode.invalidConfirmation,
          'Confirmation token is invalid, expired, or already used.',
        ),
      ]);
      return _result(
        WriteOutcome.rejected,
        invalid,
        before,
        change,
        null,
        context.state,
        null,
        diff,
      );
    }
    try {
      audit.append('write_attempt', {'idempotency_key': key});
      await transport
          ._commit(
            change.definition.id,
            change.definition.codec.encode(change.requestedValue),
            key,
          )
          .timeout(const Duration(seconds: 5));
      _completedKeys.add(key);
      final readback = await transport
          .readParameter(change.definition.id)
          .timeout(const Duration(seconds: 5));
      audit.append('write_readback', {'value': readback});
      final matches = change.definition.codec.sameRaw(
        readback,
        change.requestedValue,
      );
      audit.append('write_verify', {'matched': matches});
      if (!matches) {
        return _failed(
          validation,
          before,
          change,
          readback,
          snapshot,
          diff,
          'Readback mismatch; no automatic restore was attempted.',
        );
      }
      audit.append('write_audit', {'outcome': 'applied'});
      return _result(
        WriteOutcome.applied,
        validation,
        before,
        change,
        readback,
        DeviceWriteState.known,
        null,
        diff,
      );
    } catch (error) {
      audit.append('write_audit', {
        'outcome': 'failed',
        'error': error.runtimeType.toString(),
      });
      return _failed(
        validation,
        before,
        change,
        null,
        snapshot,
        diff,
        'Write or readback failed; verify the device before restoring.',
      );
    }
  }

  WriteResult _failed(
    ValidationResult validation,
    num before,
    ParameterChange change,
    num? readback,
    ParameterSnapshot snapshot,
    DiffReview diff,
    String reason,
  ) => _result(
    WriteOutcome.failed,
    validation,
    before,
    change,
    readback,
    DeviceWriteState.unknownVerify,
    RestorePlan(snapshot: snapshot, reason: reason),
    diff,
  );
  WriteResult _result(
    WriteOutcome outcome,
    ValidationResult validation,
    num? before,
    ParameterChange change,
    num? readback,
    DeviceWriteState state,
    RestorePlan? restore,
    DiffReview? diff,
  ) => WriteResult(
    outcome: outcome,
    validation: validation,
    before: before,
    requested: change.requestedValue,
    readback: readback,
    auditHead: audit.head,
    deviceState: state,
    restorePlan: restore,
    diff: diff,
  );
  DiffReview _diff(
    ParameterChange change,
    num before,
    DeviceWriteContext context,
  ) => DiffReview(
    parameterId: change.definition.id,
    before: before,
    after: change.requestedValue,
    risk: change.definition.riskTier,
    consequenceEn:
        'Changes ${change.definition.id} from $before to ${change.requestedValue} ${change.definition.unit}.',
    consequenceAr:
        'يغيّر ${change.definition.id} من $before إلى ${change.requestedValue} ${change.definition.unit}.',
    hash: previewHash(change, before, context),
  );
  static String previewHash(
    ParameterChange change,
    num before,
    DeviceWriteContext context,
  ) => sha256
      .convert(
        utf8.encode(
          '${context.deviceId}|${context.sessionId}|${change.definition.id}|$before|${change.requestedValue}',
        ),
      )
      .toString();
}
