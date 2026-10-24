import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/identification/identification_state_machine.dart';
import 'package:solardiag_pro/gateway/gateway_contract.dart';
import 'package:solardiag_pro/protocol/bms_adapter.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/protocol/profile_registry.dart';
import 'package:solardiag_pro/simulator/simulated_bms_adapter.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';
import 'package:solardiag_pro/transport/safe_frame_transport.dart';

void main() {
  group('deterministic simulator', () {
    test('same scenario and tick produce identical measurements', () {
      final first = ScenarioFactory.create(SimulationScenario.healthy, tick: 4);
      final second = ScenarioFactory.create(
        SimulationScenario.healthy,
        tick: 4,
      );
      expect(first.snapshot.voltage.value, second.snapshot.voltage.value);
      expect(first.snapshot.cellVoltages, second.snapshot.cellVoltages);
      expect(first.snapshot.timestamp, second.snapshot.timestamp);
    });
    test('missing temperature carries an explicit reason', () {
      final frame = ScenarioFactory.create(
        SimulationScenario.communicationFaults,
        tick: 2,
      );
      expect(frame.snapshot.temperature.value, isNull);
      expect(
        frame.snapshot.temperature.absenceReason,
        DataAbsenceReason.readFailed,
      );
    });
    test('intermittent link fails only on deterministic odd ticks', () async {
      final adapter = SimulatedBmsAdapter(
        scenario: SimulationScenario.communicationFaults,
      );
      expect((await adapter.readTelemetry()).voltage.value, isNotNull);
      adapter.advance();
      expect(adapter.readTelemetry, throwsA(isA<LinkUnavailableException>()));
    });
    test('imbalanced scenario exposes a meaningful cell delta', () {
      final frame = ScenarioFactory.create(
        SimulationScenario.gradualImbalance,
        tick: 10,
      );
      expect(frame.snapshot.cellDelta, greaterThan(.05));
    });
  });

  group('identification state machine', () {
    late DeviceProfile profile;
    setUp(() {
      final document = File(
        'device_profiles/batteries/_simulated/solardiag_sim.json',
      ).readAsStringSync();
      profile = ProfileRegistry.fromJsonDocuments(
        [document],
        technicianMode: true,
        isBundled: true,
      ).profiles.single;
    });
    test(
      'single passive observation needs confirmation without transmitting',
      () async {
        var queries = 0;
        final machine = IdentificationStateMachine(
          profiles: [profile],
          transport: _transport(GatewayOperatingMode.listenOnly),
          parseResponse: (_) async {
            queries++;
            return const IdentificationResult(
              confidence: 0,
              evidence: [],
              candidateProfileIds: [],
            );
          },
        );
        final outcome = await machine.run(
          const GatewayObservation(
            available: true,
            interfaces: {InterfaceType.simulator},
            observedIdentifiers: {769},
          ),
        );
        expect(outcome.state, IdentificationState.needsConfirmation);
        expect(queries, 0);
        expect(machine.history, contains(IdentificationState.passiveObserve));
        expect(machine.history, isNot(contains(IdentificationState.safeQuery)));
      },
    );
    test(
      'uses a declared read query when passive evidence is insufficient',
      () async {
        int? queriedIdentifier;
        final machine = IdentificationStateMachine(
          profiles: [profile],
          transport: _transport(GatewayOperatingMode.activeRead),
          parseResponse: (frame) async {
            queriedIdentifier = frame.identifier;
            return IdentificationResult(
              confidence: .98,
              evidence: const ['documented-id-response'],
              candidateProfileIds: [profile.id],
            );
          },
        );
        final outcome = await machine.run(
          const GatewayObservation(
            available: true,
            interfaces: {InterfaceType.simulator},
            observedIdentifiers: {},
          ),
        );
        expect(outcome.confirmed, isTrue);
        expect(profile.allowedReadFrames, contains(queriedIdentifier));
        expect(
          machine.history,
          containsAllInOrder([
            IdentificationState.passiveObserve,
            IdentificationState.safeQuery,
            IdentificationState.parseIdentity,
            IdentificationState.matchProfile,
            IdentificationState.confirm,
          ]),
        );
      },
    );
    test('stops when gateway is unavailable', () async {
      final machine = IdentificationStateMachine(
        profiles: [profile],
        transport: _transport(GatewayOperatingMode.listenOnly),
        parseResponse: (_) => throw StateError('must not query'),
      );
      final outcome = await machine.run(
        const GatewayObservation(
          available: false,
          interfaces: {},
          observedIdentifiers: {},
        ),
      );
      expect(outcome.state, IdentificationState.failed);
      expect(machine.history, isNot(contains(IdentificationState.safeQuery)));
    });
    test('reports unsupported interface without probing', () async {
      var queried = false;
      final machine = IdentificationStateMachine(
        profiles: [profile],
        transport: _transport(GatewayOperatingMode.listenOnly),
        parseResponse: (_) async {
          queried = true;
          return const IdentificationResult(
            confidence: 1,
            evidence: [],
            candidateProfileIds: [],
          );
        },
      );
      final outcome = await machine.run(
        const GatewayObservation(
          available: true,
          interfaces: {InterfaceType.can},
          observedIdentifiers: {},
        ),
      );
      expect(outcome.state, IdentificationState.unsupported);
      expect(queried, isFalse);
    });

    test('manual selection is exact and explicitly flagged', () {
      final machine = IdentificationStateMachine(
        profiles: [profile],
        transport: _transport(GatewayOperatingMode.listenOnly),
        parseResponse: (_) => throw StateError('must not query'),
      );
      final outcome = machine.selectManually(
        manufacturer: profile.manufacturer,
        family: profile.family,
        model: profile.models.first,
        firmware: profile.firmwareRanges.first,
      );
      expect(outcome.confirmed, isTrue);
      expect(outcome.manuallySelected, isTrue);
      expect(outcome.evidence, contains('manual-selection'));
    });

    test('query timeout honors bounded retries', () async {
      var attempts = 0;
      final machine = IdentificationStateMachine(
        profiles: [profile],
        transport: _transport(GatewayOperatingMode.activeRead),
        queryTimeout: const Duration(milliseconds: 5),
        maxRetries: 1,
        globalBudget: const Duration(milliseconds: 100),
        parseResponse: (_) async {
          attempts++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return const IdentificationResult(
            confidence: 0,
            evidence: [],
            candidateProfileIds: [],
          );
        },
      );
      final outcome = await machine.run(
        const GatewayObservation(
          available: true,
          interfaces: {InterfaceType.simulator},
          observedIdentifiers: {},
        ),
      );
      expect(outcome.state, IdentificationState.unsupported);
      expect(attempts, 2);
      expect(
        outcome.evidence.where((e) => e.startsWith('query-timeout')),
        hasLength(2),
      );
    });
  });
}

LoopbackGatewayTransport _transport(GatewayOperatingMode mode) =>
    LoopbackGatewayTransport(
      mode: mode,
      guard: const TransmissionGuard(
        allowedReadIdentifiers: {769},
        allowedWriteIdentifiers: {},
        activeSession: true,
        profileVerifiedForHardware: false,
      ),
      maxFramesPerSecond: 4,
      busLoadCap: .1,
      audit: AuditChain(),
    );
