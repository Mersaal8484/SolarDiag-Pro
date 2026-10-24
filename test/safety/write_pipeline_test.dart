import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/parameters/parameter_backup.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';
import '../support/test_secret_store.dart';

void main() {
  AuditChain createAudit({DateTime Function()? clock}) => AuditChain(
    clock: clock,
    secretStore: TestSecretStore(),
  );

  const definition = ParameterDefinition(
    id: 'charge_limit',
    unit: 'V',
    minimum: 50,
    maximum: 56,
    step: .1,
    scale: .1,
    riskTier: ParameterRiskTier.advanced,
    requiredAuthorization: AuthorizationTier.technician,
    writeVerifiedOnHardware: true,
    dependencies: [
      ParameterDependency(parameterId: 'service_mode', allowedValues: {1}),
    ],
  );
  const unverified = ParameterDefinition(
    id: 'unverified',
    unit: 'V',
    minimum: 0,
    maximum: 10,
    step: .1,
    scale: .1,
    riskTier: ParameterRiskTier.standard,
    requiredAuthorization: AuthorizationTier.viewer,
    writeVerifiedOnHardware: false,
  );
  final now = DateTime.utc(2026);
  AuthorizationSession auth() => AuthorizationSession(
    tier: AuthorizationTier.technician,
    expiresAt: now.add(const Duration(hours: 1)),
  );
  const context = DeviceWriteContext(
    deviceId: 'battery-1',
    sessionId: 'session-1',
    profileModel: 'model',
    profileFirmware: '1.0',
    connectedModel: 'model',
    connectedFirmware: '1.0',
    linkHealthy: true,
    writeLocked: false,
    state: DeviceWriteState.known,
  );
  ConfirmationToken token(
    ParameterChange change,
    num before, {
    DeviceWriteContext target = context,
  }) => ConfirmationToken(
    diffHash: VerifiedWritePipeline.previewHash(change, before, target),
    deviceId: target.deviceId,
    sessionId: target.sessionId,
    expiresAt: now.add(const Duration(minutes: 5)),
  );

  test('missing measurement never becomes zero', () {
    const value = Measurement.absent(DataAbsenceReason.notReported);
    expect(value.value, isNull);
  });

  test('codec compares exact raw values without decimal false mismatch', () {
    const codec = ParameterCodec(scale: .1, step: .1);
    expect(codec.decode(codec.encode(3.6)), closeTo(3.6, 1e-12));
    expect(codec.sameRaw(55.2, 55.20000000000001), isTrue);
  });

  test(
    'physical unverified write cannot be marked simulated by caller',
    () async {
      final harness = _Harness({'unverified': 1});
      final change = const ParameterChange(
        definition: unverified,
        requestedValue: 2,
      );
      final result =
          await VerifiedWritePipeline(
            transport: harness.physical,
            audit: createAudit(),
            clock: () => now,
          ).execute(
            change: change,
            authorization: auth(),
            safetyAcknowledged: true,
            context: context,
            confirmation: token(change, 1),
            idempotencyKey: 'physical',
          );
      expect(
        result.validation.issues.map((e) => e.code),
        contains(ValidationCode.unverifiedWrite),
      );
      expect(harness.writeCount, 0);
    },
  );

  test('unavailable audit key rejects a write before transport access', () async {
    final harness = _Harness({'charge_limit': 54, 'service_mode': 1});
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final result = await VerifiedWritePipeline(
      transport: harness.physical,
      audit: AuditChain(),
      clock: () => now,
    ).execute(
      change: change,
      authorization: auth(),
      safetyAcknowledged: true,
      context: context,
      confirmation: token(change, 54),
      idempotencyKey: 'missing-audit-key',
    );

    expect(result.outcome, WriteOutcome.rejected);
    expect(
      result.validation.issues.map((issue) => issue.code),
      contains(ValidationCode.auditKeyUnavailable),
    );
    expect(harness.writeCount, 0);
  });

  test('verified pipeline records nine stages and applies once', () async {
    final harness = _Harness({'charge_limit': 54, 'service_mode': 1});
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final audit = createAudit(clock: () => now);
    final result =
        await VerifiedWritePipeline(
          transport: harness.physical,
          audit: audit,
          clock: () => now,
        ).execute(
          change: change,
          authorization: auth(),
          safetyAcknowledged: true,
          context: context,
          confirmation: token(change, 54),
          idempotencyKey: 'apply',
        );
    expect(result.outcome, WriteOutcome.applied);
    expect(harness.writeCount, 1);
    expect(
      audit.entries.map((e) => e.action),
      containsAll([
        'write_preflight',
        'write_snapshot',
        'write_validate',
        'write_preview',
        'write_confirm',
        'write_attempt',
        'write_readback',
        'write_verify',
        'write_audit',
      ]),
    );
  });

  test(
    'mismatch never writes twice and returns separate restore plan',
    () async {
      final harness = _Harness({
        'charge_limit': 54,
        'service_mode': 1,
      }, mismatch: true);
      const change = ParameterChange(
        definition: definition,
        requestedValue: 55.2,
      );
      final result =
          await VerifiedWritePipeline(
            transport: harness.physical,
            audit: createAudit(),
            clock: () => now,
          ).execute(
            change: change,
            authorization: auth(),
            safetyAcknowledged: true,
            context: context,
            confirmation: token(change, 54),
            idempotencyKey: 'mismatch',
          );
      expect(result.outcome, WriteOutcome.failed);
      expect(result.deviceState, DeviceWriteState.unknownVerify);
      expect(result.restorePlan!.snapshot.values['charge_limit'], 54);
      expect(harness.writeCount, 1);
    },
  );

  test('token replay and token for another diff are rejected', () async {
    final harness = _Harness({'charge_limit': 54, 'service_mode': 1});
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final pipeline = VerifiedWritePipeline(
      transport: harness.physical,
      audit: createAudit(),
      clock: () => now,
    );
    final confirmation = token(change, 54);
    expect(
      (await pipeline.execute(
        change: change,
        authorization: auth(),
        safetyAcknowledged: true,
        context: context,
        confirmation: confirmation,
        idempotencyKey: 'one',
      )).outcome,
      WriteOutcome.applied,
    );
    harness.values['charge_limit'] = 54;
    expect(
      (await pipeline.execute(
        change: change,
        authorization: auth(),
        safetyAcknowledged: true,
        context: context,
        confirmation: confirmation,
        idempotencyKey: 'two',
      )).outcome,
      WriteOutcome.rejected,
    );
    final wrong = ConfirmationToken(
      diffHash: 'wrong',
      deviceId: context.deviceId,
      sessionId: context.sessionId,
      expiresAt: now.add(const Duration(minutes: 1)),
    );
    expect(
      (await pipeline.execute(
        change: change,
        authorization: auth(),
        safetyAcknowledged: true,
        context: context,
        confirmation: wrong,
        idempotencyKey: 'three',
      )).outcome,
      WriteOutcome.rejected,
    );
  });

  test('duplicate idempotency key writes once', () async {
    final harness = _Harness({'charge_limit': 54, 'service_mode': 1});
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final pipeline = VerifiedWritePipeline(
      transport: harness.physical,
      audit: createAudit(),
      clock: () => now,
    );
    await pipeline.execute(
      change: change,
      authorization: auth(),
      safetyAcknowledged: true,
      context: context,
      confirmation: token(change, 54),
      idempotencyKey: 'same',
    );
    final duplicate = await pipeline.execute(
      change: change,
      authorization: auth(),
      safetyAcknowledged: true,
      context: context,
      confirmation: token(change, 55.2),
      idempotencyKey: 'same',
    );
    expect(duplicate.outcome, WriteOutcome.rejected);
    expect(harness.writeCount, 1);
  });

  test('link loss during readback marks state unknown', () async {
    final harness = _Harness({
      'charge_limit': 54,
      'service_mode': 1,
    }, failReadback: true);
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final result =
        await VerifiedWritePipeline(
          transport: harness.physical,
          audit: createAudit(),
          clock: () => now,
        ).execute(
          change: change,
          authorization: auth(),
          safetyAcknowledged: true,
          context: context,
          confirmation: token(change, 54),
          idempotencyKey: 'link-loss',
        );
    expect(result.outcome, WriteOutcome.failed);
    expect(result.deviceState, DeviceWriteState.unknownVerify);
    expect(result.restorePlan, isNotNull);
  });

  test('concurrent writes are serialized', () async {
    final harness = _Harness({
      'charge_limit': 54,
      'service_mode': 1,
    }, writeDelay: const Duration(milliseconds: 15));
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final pipeline = VerifiedWritePipeline(
      transport: harness.physical,
      audit: createAudit(),
      clock: () => now,
    );
    await Future.wait([
      pipeline.execute(
        change: change,
        authorization: auth(),
        safetyAcknowledged: true,
        context: context,
        confirmation: token(change, 54),
        idempotencyKey: 'concurrent-1',
      ),
      pipeline.execute(
        change: change,
        authorization: auth(),
        safetyAcknowledged: true,
        context: context,
        confirmation: token(change, 55.2),
        idempotencyKey: 'concurrent-2',
      ),
    ]);
    expect(harness.maximumConcurrentWrites, 1);
  });

  test('cross-parameter constraints are enforced', () async {
    const constrained = ParameterDefinition(
      id: 'cell_ovp',
      unit: 'V',
      minimum: 3,
      maximum: 4,
      step: .1,
      scale: .1,
      riskTier: ParameterRiskTier.standard,
      requiredAuthorization: AuthorizationTier.viewer,
      writeVerifiedOnHardware: true,
      constraints: [
        ParameterConstraint(
          otherParameterId: 'cell_ovp_recover',
          relation: ConstraintRelation.greaterThan,
        ),
      ],
    );
    final harness = _Harness({'cell_ovp': 3.6, 'cell_ovp_recover': 3.5});
    const change = ParameterChange(
      definition: constrained,
      requestedValue: 3.4,
    );
    final result =
        await VerifiedWritePipeline(
          transport: harness.physical,
          audit: createAudit(),
          clock: () => now,
        ).execute(
          change: change,
          authorization: auth(),
          safetyAcknowledged: true,
          context: context,
          confirmation: token(change, 3.6),
          idempotencyKey: 'constraint',
        );
    expect(
      result.validation.issues.map((e) => e.code),
      contains(ValidationCode.crossParameterConstraint),
    );
    expect(harness.writeCount, 0);
  });

  test(
    'expired authorization, unhealthy link, and unknown state fail preflight',
    () async {
      final harness = _Harness({'charge_limit': 54, 'service_mode': 1});
      const change = ParameterChange(
        definition: definition,
        requestedValue: 55.2,
      );
      const unsafe = DeviceWriteContext(
        deviceId: 'battery-1',
        sessionId: 'session-1',
        profileModel: 'model',
        profileFirmware: '1.0',
        connectedModel: 'model',
        connectedFirmware: '1.0',
        linkHealthy: false,
        writeLocked: false,
        state: DeviceWriteState.unknownVerify,
      );
      final result =
          await VerifiedWritePipeline(
            transport: harness.physical,
            audit: createAudit(),
            clock: () => now,
          ).execute(
            change: change,
            authorization: AuthorizationSession(
              tier: AuthorizationTier.technician,
              expiresAt: now,
            ),
            safetyAcknowledged: true,
            context: unsafe,
            confirmation: token(change, 54, target: unsafe),
            idempotencyKey: 'unsafe',
          );
      expect(
        result.validation.issues.map((e) => e.code),
        containsAll([
          ValidationCode.expiredAuthorization,
          ValidationCode.unhealthyLink,
          ValidationCode.unknownDeviceState,
        ]),
      );
      expect(harness.writeCount, 0);
    },
  );

  test('restore is a separate newly confirmed execution', () async {
    final harness = _Harness({
      'charge_limit': 54,
      'service_mode': 1,
    }, mismatch: true);
    const change = ParameterChange(
      definition: definition,
      requestedValue: 55.2,
    );
    final pipeline = VerifiedWritePipeline(
      transport: harness.physical,
      audit: createAudit(),
      clock: () => now,
    );
    final failed = await pipeline.execute(
      change: change,
      authorization: auth(),
      safetyAcknowledged: true,
      context: context,
      confirmation: token(change, 54),
      idempotencyKey: 'failed-change',
    );
    expect(harness.writeCount, 1);
    harness.mismatch = false;
    const restore = ParameterChange(definition: definition, requestedValue: 54);
    final restored = await pipeline.execute(
      change: restore,
      authorization: auth(),
      safetyAcknowledged: true,
      context: context,
      confirmation: token(restore, 55.2),
      idempotencyKey: 'explicit-restore',
    );
    expect(failed.restorePlan, isNotNull);
    expect(restored.outcome, WriteOutcome.applied);
    expect(harness.writeCount, 2);
  });

  test('configuration backup round-trips and rejects another device', () {
    final backup = ParameterBackup(
      schemaVersion: 1,
      profileId: 'profile',
      deviceIdentity: 'battery-1',
      firmware: '1.0',
      capturedAt: now,
      values: const {'charge_limit': 55.2},
    );
    final decoded = ParameterBackup.fromJson(backup.toJson());
    final plan = decoded.planRestore(
      activeProfileId: 'profile',
      activeDeviceIdentity: 'battery-1',
      activeFirmware: '1.0',
      definitions: const {'charge_limit': definition},
      current: ParameterSnapshot({'charge_limit': 54}, capturedAt: now),
    );
    expect(plan.single.requestedValue, 55.2);
    expect(
      () => decoded.planRestore(
        activeProfileId: 'profile',
        activeDeviceIdentity: 'other',
        activeFirmware: '1.0',
        definitions: const {'charge_limit': definition},
        current: ParameterSnapshot({'charge_limit': 54}, capturedAt: now),
      ),
      throwsFormatException,
    );
  });

  test('architecture has one write path and no duplicate pipeline', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final offenders = dartFiles
        .where((f) => f.readAsStringSync().contains('writeParameter('))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
    expect(File('lib/core/safe_write_pipeline.dart').existsSync(), isFalse);
  });
}

class _Harness {
  _Harness(
    this.values, {
    this.mismatch = false,
    this.failReadback = false,
    this.writeDelay = Duration.zero,
  });
  final Map<String, num> values;
  bool mismatch;
  final bool failReadback;
  final Duration writeDelay;
  int writeCount = 0;
  int _activeWrites = 0;
  int maximumConcurrentWrites = 0;
  late final ParameterTransport physical = ParameterTransport.physical(
    read: (id) async {
      if (failReadback) {
        throw StateError('link lost');
      }
      return mismatch ? values[id]! + 1 : values[id]!;
    },
    readAll: () async => Map.of(values),
    write: (id, raw, _) async {
      writeCount++;
      _activeWrites++;
      if (_activeWrites > maximumConcurrentWrites) {
        maximumConcurrentWrites = _activeWrites;
      }
      await Future<void>.delayed(writeDelay);
      values[id] = raw * .1;
      _activeWrites--;
    },
  );
}
