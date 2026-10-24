import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/auth/authorization_controller.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';
import 'package:solardiag_pro/persistence/local_database.dart';

void main() {
  test('session reads changing telemetry through the adapter', () async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
    );
    addTearDown(session.dispose);

    await session.refresh();
    final firstSoc = session.snapshot.soc.value;
    await session.refresh();

    expect(firstSoc, 78);
    expect(session.snapshot.soc.value, 77);
    expect(session.linkState, DeviceSessionLinkState.online);
    expect(session.linkHealth, isNotNull);
    expect(session.simulated, isTrue);
    expect(session.mode, DeviceSessionMode.readOnly);
  });

  test(
    'link failure is explicit and preserves the last good snapshot',
    () async {
      final session = DeviceSession(
        scenario: SimulationScenario.communicationFaults,
        autoStart: false,
      );
      addTearDown(session.dispose);

      await session.refresh();
      final lastGood = session.snapshot;
      await session.refresh();

      expect(session.linkState, DeviceSessionLinkState.unavailable);
      expect(session.lastError, isNotNull);
      expect(session.snapshot, same(lastGood));
    },
  );

  test('scenario selection replaces the adapter and snapshot', () async {
    final session = DeviceSession(autoStart: false);
    addTearDown(session.dispose);

    await session.selectScenario(SimulationScenario.highTemperature);

    expect(session.scenario, SimulationScenario.highTemperature);
    expect(session.snapshot.temperature.value, 63);
    expect(session.linkState, DeviceSessionLinkState.online);
  });

  test('link diagnostics are derived from live session health', () async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
    );
    addTearDown(session.dispose);

    await session.refresh();

    expect(session.linkDiagnostics.messageDeliveryRatio, 1);
    expect(session.linkDiagnostics.findings, isNotEmpty);
    expect(session.compatibilityAssessment.findings, isNotEmpty);
  });

  test('parameters and backups come from the active adapter', () async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
    );
    addTearDown(session.dispose);

    await session.refreshParameters();
    final backup = session.createParameterBackup();

    expect(session.parameters['charge_limit'], 55.2);
    expect(backup.values, session.parameters);
    expect(session.backups, hasLength(1));
    expect(backup.profileId, 'solardiag.simulated.lfp16.v2');
  });

  test(
    'simulated parameter change uses verified pipeline and readback',
    () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        authenticator: const DemoConfiguration(
          isDemoMode: true,
          demoPin: 'pin',
        ).createAuthenticator(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refreshParameters();

      await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'pin',
      );
      final before = session.parameters['charge_limit']!;
      final context = session.createWriteContext();
      final diffHash = VerifiedWritePipeline.previewHash(
        ParameterChange(
          definition: DeviceSession.parameterDefinitions['charge_limit']!,
          requestedValue: 54.8,
        ),
        before,
        context,
      );
      final confirmation = ConfirmationToken(
        diffHash: diffHash,
        deviceId: context.deviceId,
        sessionId: context.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final result = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: session.auth.current!,
        confirmation: confirmation,
        safetyAcknowledged: true,
      );

      expect(result.outcome, WriteOutcome.applied);
      expect(result.readback, closeTo(54.8, 1e-9));
      expect(session.parameters['charge_limit'], closeTo(54.8, 1e-9));
      expect(result.auditHead, isNot('GENESIS'));
    },
  );

  test('advanced simulated change requires safety acknowledgement', () async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      authenticator: const DemoConfiguration(
        isDemoMode: true,
        demoPin: 'pin',
      ).createAuthenticator(),
    );
    addTearDown(session.dispose);
    await session.refresh();
    await session.refreshParameters();

    await session.auth.unlock(
      tier: AuthorizationTier.technician,
      credentials: 'pin',
    );
    final before = session.parameters['charge_limit']!;
    final context = session.createWriteContext();
    final diffHash = VerifiedWritePipeline.previewHash(
      ParameterChange(
        definition: DeviceSession.parameterDefinitions['charge_limit']!,
        requestedValue: 54.8,
      ),
      before,
      context,
    );
    final confirmation = ConfirmationToken(
      diffHash: diffHash,
      deviceId: context.deviceId,
      sessionId: context.sessionId,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );

    final result = await session.applySimulatedParameterChange(
      parameterId: 'charge_limit',
      requestedValue: 54.8,
      authorization: session.auth.current!,
      confirmation: confirmation,
      safetyAcknowledged: false,
    );

    expect(result.outcome, WriteOutcome.rejected);
    expect(
      result.validation.issues.map((issue) => issue.code),
      contains(ValidationCode.acknowledgementRequired),
    );
    expect(session.parameters['charge_limit'], 55.2);
  });

  test('successful telemetry is persisted with an integrity hash', () async {
    final database = LocalDatabase.inMemory();
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      database: database,
    );
    addTearDown(session.dispose);
    addTearDown(database.close);

    await session.refresh();
    final first = database.listSessions().single;
    await session.refresh();
    final updated = database.listSessions().single;

    expect(first.scenario, 'healthy');
    expect(first.dataHash, hasLength(64));
    expect(updated.id, first.id);
    expect(updated.snapshotJson, isNot(first.snapshotJson));
    expect(session.history, hasLength(1));
    expect(session.eventsFor(first.id), hasLength(3));
    expect(session.eventsFor(first.id).map((event) => event.type), [
      'session_started',
      'link_state_changed',
      'alarms_changed',
    ]);
  });

  test('parameter backups are restored into a later session', () async {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final first = DeviceSession(autoStart: false, database: database);
    await first.refreshParameters();
    final backup = first.createParameterBackup();
    first.dispose();

    final restored = DeviceSession(autoStart: false, database: database);
    addTearDown(restored.dispose);

    expect(restored.backups, hasLength(1));
    expect(restored.backups.single.capturedAt, backup.capturedAt);
    expect(restored.backups.single.values, backup.values);
  });

  test('backup restore uses verified writes and readback', () async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      authenticator: const DemoConfiguration(
        isDemoMode: true,
        demoPin: 'pin',
      ).createAuthenticator(),
    );
    addTearDown(session.dispose);
    await session.refresh();
    await session.refreshParameters();
    final backup = session.createParameterBackup();
    await session.auth.unlock(
      tier: AuthorizationTier.technician,
      credentials: 'pin',
    );
    final context1 = session.createWriteContext();
    final diffHash1 = VerifiedWritePipeline.previewHash(
      ParameterChange(
        definition: DeviceSession.parameterDefinitions['charge_limit']!,
        requestedValue: 54.8,
      ),
      session.parameters['charge_limit']!,
      context1,
    );
    final changed = await session.applySimulatedParameterChange(
      parameterId: 'charge_limit',
      requestedValue: 54.8,
      authorization: session.auth.current!,
      confirmation: ConfirmationToken(
        diffHash: diffHash1,
        deviceId: context1.deviceId,
        sessionId: context1.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      ),
      safetyAcknowledged: true,
    );
    expect(changed.outcome, WriteOutcome.applied);

    final context2 = session.createWriteContext();
    final diffHash2 = VerifiedWritePipeline.previewHash(
      ParameterChange(
        definition: DeviceSession.parameterDefinitions['charge_limit']!,
        requestedValue: 55.2,
      ),
      session.parameters['charge_limit']!,
      context2,
    );
    final plan = session.planRestore(backup);
    final restored = await session.restoreParameterBackup(
      plan: plan,
      authorization: session.auth.current!,
      confirmations: [
        ConfirmationToken(
          diffHash: diffHash2,
          deviceId: context2.deviceId,
          sessionId: context2.sessionId,
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        ),
      ],
      safetyAcknowledged: true,
    );

    expect(restored, hasLength(1));
    expect(restored.single.outcome, WriteOutcome.applied);
    expect(restored.single.readback, closeTo(55.2, 1e-9));
    expect(session.parameters['charge_limit'], closeTo(55.2, 1e-9));
  });

  test(
    'forced simulator readback mismatch returns a separate restore plan',
    () async {
      final session = DeviceSession(
        scenario: SimulationScenario.parameterProfile,
        autoStart: false,
        authenticator: const DemoConfiguration(
          isDemoMode: true,
          demoPin: 'pin',
        ).createAuthenticator(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refresh();
      await session.refreshParameters();

      await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'pin',
      );
      final before = session.parameters['charge_limit']!;
      final context = session.createWriteContext();
      final diffHash = VerifiedWritePipeline.previewHash(
        ParameterChange(
          definition: DeviceSession.parameterDefinitions['charge_limit']!,
          requestedValue: 54.8,
        ),
        before,
        context,
      );
      final result = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: session.auth.current!,
        confirmation: ConfirmationToken(
          diffHash: diffHash,
          deviceId: context.deviceId,
          sessionId: context.sessionId,
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        ),
        safetyAcknowledged: true,
      );

      expect(result.outcome, WriteOutcome.failed);
      expect(result.restorePlan, isNotNull);
      expect(result.deviceState, DeviceWriteState.unknownVerify);
    },
  );

  test(
    'session exposes changing inverter telemetry from its adapter',
    () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
      );
      addTearDown(session.dispose);

      await session.refresh();
      final first = session.inverterSnapshot;
      await session.refresh();

      expect(first?.acVoltage.value, 230);
      expect(first?.dcVoltage.value, 54);
      expect(session.inverterSnapshot?.dcVoltage.value, closeTo(54.01, 1e-9));
    },
  );
}
