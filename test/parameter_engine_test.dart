import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/parameters/parameter_backup.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/parameter_validator.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';

void main() {
  const definition = ParameterDefinition(
    id: 'charge_limit',
    unit: 'V',
    minimum: 50,
    maximum: 56,
    step: .1,
    riskTier: ParameterRiskTier.advanced,
    requiredAuthorization: AuthorizationTier.technician,
    writeVerifiedOnHardware: true,
    dependencies: [
      ParameterDependency(parameterId: 'service_mode', allowedValues: {1}),
    ],
  );
  ParameterSnapshot current() => ParameterSnapshot({
    'charge_limit': 54,
    'service_mode': 1,
  }, capturedAt: DateTime.utc(2026));

  group('parameter validation', () {
    test('accepts value only when all gates pass', () {
      final result = const ParameterValidator().validate(
        change: const ParameterChange(
          definition: definition,
          requestedValue: 55.2,
        ),
        current: current(),
        authorization: AuthorizationTier.technician,
        safetyAcknowledged: true,
        simulatedSession: false,
      );
      expect(result.isValid, isTrue);
    });
    test(
      'rejects range, step, authorization, acknowledgement and dependency',
      () {
        final snapshot = ParameterSnapshot({
          'charge_limit': 54,
          'service_mode': 0,
        }, capturedAt: DateTime.utc(2026));
        final result = const ParameterValidator().validate(
          change: const ParameterChange(
            definition: definition,
            requestedValue: 56.05,
          ),
          current: snapshot,
          authorization: AuthorizationTier.viewer,
          safetyAcknowledged: false,
          simulatedSession: false,
        );
        expect(
          result.issues.map((issue) => issue.code),
          containsAll([
            ValidationCode.aboveMaximum,
            ValidationCode.invalidStep,
            ValidationCode.insufficientAuthorization,
            ValidationCode.acknowledgementRequired,
            ValidationCode.unmetDependency,
          ]),
        );
      },
    );
    test(
      'unverified physical write is rejected but simulator stays isolated',
      () {
        const unverified = ParameterDefinition(
          id: 'x',
          unit: 'V',
          minimum: 0,
          maximum: 10,
          step: 1,
          riskTier: ParameterRiskTier.standard,
          requiredAuthorization: AuthorizationTier.viewer,
          writeVerifiedOnHardware: false,
        );
        final snapshot = ParameterSnapshot({
          'x': 1,
        }, capturedAt: DateTime.utc(2026));
        final physical = const ParameterValidator().validate(
          change: const ParameterChange(
            definition: unverified,
            requestedValue: 2,
          ),
          current: snapshot,
          authorization: AuthorizationTier.viewer,
          safetyAcknowledged: false,
          simulatedSession: false,
        );
        final simulated = const ParameterValidator().validate(
          change: const ParameterChange(
            definition: unverified,
            requestedValue: 2,
          ),
          current: snapshot,
          authorization: AuthorizationTier.viewer,
          safetyAcknowledged: false,
          simulatedSession: true,
        );
        expect(
          physical.issues.map((issue) => issue.code),
          contains(ValidationCode.unverifiedWrite),
        );
        expect(simulated.isValid, isTrue);
      },
    );
  });

  group('verified write pipeline', () {
    test('writes, reads back, and records a valid audit chain', () async {
      final transport = _FakeTransport({'charge_limit': 54});
      final audit = AuditChain(clock: () => DateTime.utc(2026, 1, 1));
      final result =
          await VerifiedWritePipeline(
            transport: transport,
            audit: audit,
          ).execute(
            change: const ParameterChange(
              definition: definition,
              requestedValue: 55.2,
            ),
            current: current(),
            authorization: AuthorizationTier.technician,
            safetyAcknowledged: true,
            simulatedSession: false,
          );
      expect(result.outcome, WriteOutcome.applied);
      expect(result.readback, 55.2);
      expect(audit.entries.map((entry) => entry.action), [
        'parameter_write_started',
        'parameter_write_verified',
      ]);
      expect(audit.verify(), isTrue);
    });
    test('never calls transport when validation fails', () async {
      final transport = _FakeTransport({'charge_limit': 54});
      final result =
          await VerifiedWritePipeline(
            transport: transport,
            audit: AuditChain(),
          ).execute(
            change: const ParameterChange(
              definition: definition,
              requestedValue: 60,
            ),
            current: current(),
            authorization: AuthorizationTier.viewer,
            safetyAcknowledged: false,
            simulatedSession: false,
          );
      expect(result.outcome, WriteOutcome.rejected);
      expect(transport.writeCount, 0);
    });
    test('readback mismatch rolls back to known previous value', () async {
      final transport = _FakeTransport({
        'charge_limit': 54,
      }, mismatchOnce: true);
      final audit = AuditChain();
      final result =
          await VerifiedWritePipeline(
            transport: transport,
            audit: audit,
          ).execute(
            change: const ParameterChange(
              definition: definition,
              requestedValue: 55.2,
            ),
            current: current(),
            authorization: AuthorizationTier.technician,
            safetyAcknowledged: true,
            simulatedSession: false,
          );
      expect(result.outcome, WriteOutcome.rolledBack);
      expect(transport.values['charge_limit'], 54);
      expect(
        audit.entries.map((entry) => entry.action),
        contains('parameter_rollback_verified'),
      );
    });
  });

  group('backup and restore', () {
    final backup = ParameterBackup(
      schemaVersion: 1,
      profileId: 'sim',
      deviceIdentity: 'battery-1',
      firmware: 'sim-1',
      capturedAt: DateTime.utc(2026),
      values: const {'charge_limit': 55.2},
    );
    test('round trips and produces a restore plan', () {
      final decoded = ParameterBackup.fromJson(backup.toJson());
      final plan = decoded.planRestore(
        activeProfileId: 'sim',
        activeDeviceIdentity: 'battery-1',
        activeFirmware: 'sim-1',
        definitions: const {'charge_limit': definition},
        current: current(),
      );
      expect(plan.single.requestedValue, 55.2);
    });
    test(
      'refuses restore onto a different device',
      () => expect(
        () => backup.planRestore(
          activeProfileId: 'sim',
          activeDeviceIdentity: 'battery-2',
          activeFirmware: 'sim-1',
          definitions: const {'charge_limit': definition},
          current: current(),
        ),
        throwsFormatException,
      ),
    );
  });
}

class _FakeTransport implements ParameterTransport {
  _FakeTransport(this.values, {this.mismatchOnce = false});
  final Map<String, num> values;
  final bool mismatchOnce;
  int writeCount = 0;
  bool _mismatchPending = false;
  @override
  Future<num> readParameter(String id) async {
    if (_mismatchPending) {
      _mismatchPending = false;
      return values[id]! + 1;
    }
    return values[id]!;
  }

  @override
  Future<void> writeParameter(String id, num value) async {
    writeCount++;
    values[id] = value;
    if (mismatchOnce && writeCount == 1) _mismatchPending = true;
  }
}
