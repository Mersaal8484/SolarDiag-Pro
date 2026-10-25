import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/gateway/gateway_contract.dart';
import 'package:solardiag_pro/gateway/gateway_wire_protocol.dart';
import 'package:solardiag_pro/protocol/bms_adapter.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/protocol/research_target_registry.dart';
import 'package:solardiag_pro/transport/safe_frame_transport.dart';

void main() {
  GatewayDescriptor gateway({
    bool isolated = true,
    bool interlock = true,
    int protocolVersion = gatewayProtocolVersion,
    Set<int> bitrates = standardCanBitrates,
    Set<int> validatedCustomBitrates = const {},
  }) => GatewayDescriptor(
    protocolVersion: protocolVersion,
    hardwareRevision: 'unvalidated-prototype',
    firmwareVersion: '0.1.0-dev',
    bootId: 'ephemeral-boot-id',
    physicalTxInterlock: interlock,
    interfaces: [
      GatewayInterfaceDescriptor(
        type: InterfaceType.can,
        isolated: isolated,
        listenOnlyCapable: true,
        bitrates: bitrates,
        validatedCustomBitrates: validatedCustomBitrates,
      ),
    ],
  );

  const requirement = TransportRequirement(
    interfaceType: InterfaceType.can,
    bitrate: 500000,
    listenOnlyByDefault: true,
  );

  group('passive gateway negotiation', () {
    test('creates an explicitly non-transmitting plan', () {
      final plan = const GatewaySessionNegotiator().negotiatePassive(
        gateway(),
        requirement,
      );
      expect(plan.mode, GatewayOperatingMode.listenOnly);
      expect(plan.transmissionEnabled, isFalse);
      expect(plan.bitrate, 500000);
    });

    test('active read requires verified capability and explicit start', () {
      final plan = const GatewaySessionNegotiator().negotiateActiveRead(
        gateway(),
        requirement,
        capabilityStatus: VerificationStatus.verifiedDocument,
        explicitlyStarted: true,
        maxFramesPerSecond: 4,
        busLoadCap: .1,
      );
      expect(plan.mode, GatewayOperatingMode.activeRead);
      expect(plan.transmissionEnabled, isTrue);
      expect(plan.maxFramesPerSecond, 4);
      expect(plan.busLoadCap, .1);
      expect(
        () => const GatewaySessionNegotiator().negotiateActiveRead(
          gateway(),
          requirement,
          capabilityStatus: VerificationStatus.researchTarget,
          explicitlyStarted: true,
          maxFramesPerSecond: 4,
          busLoadCap: .1,
        ),
        throwsA(isA<GatewayContractException>()),
      );
    });

    test('rejects an unisolated interface', () {
      expect(
        () => const GatewaySessionNegotiator().negotiatePassive(
          gateway(isolated: false),
          requirement,
        ),
        throwsA(isA<GatewayContractException>()),
      );
    });

    test('rejects missing physical TX interlock', () {
      expect(
        () => const GatewaySessionNegotiator().negotiatePassive(
          gateway(interlock: false),
          requirement,
        ),
        throwsA(isA<GatewayContractException>()),
      );
    });

    test('rejects protocol and unvalidated custom bitrate mismatches', () {
      expect(
        () => const GatewaySessionNegotiator().negotiatePassive(
          gateway(protocolVersion: 2),
          requirement,
        ),
        throwsA(isA<GatewayContractException>()),
      );
      expect(
        () => const GatewaySessionNegotiator().negotiatePassive(
          gateway(),
          const TransportRequirement(
            interfaceType: InterfaceType.can,
            bitrate: 800000,
            listenOnlyByDefault: true,
          ),
        ),
        throwsA(isA<GatewayContractException>()),
      );
    });

    test('announces standard CAN rates and validated custom rates', () {
      final descriptor = GatewayDescriptor.fromJson({
        'protocol_version': gatewayProtocolVersion,
        'hardware_revision': 'contract-fixture',
        'firmware_version': 'contract-only',
        'boot_id': 'fixture-boot',
        'physical_tx_interlock': true,
        'interfaces': [
          {
            'type': 'can',
            'isolated': true,
            'listen_only_capable': true,
            'bitrates': [125000, 250000, 500000, 1000000, 833333],
            'validated_custom_bitrates': [833333],
          },
          {
            'type': 'rs485',
            'isolated': true,
            'listen_only_capable': true,
            'baud_rates': [9600, 19200],
          },
        ],
      });
      expect(descriptor.interfaces, hasLength(2));
      final can = descriptor.interfaces.first;
      expect(can.bitrates, containsAll(standardCanBitrates));
      expect(can.supportsBitrate(1000000), isTrue);
      expect(can.supportsBitrate(833333), isTrue);
      final unvalidatedCustom = GatewayDescriptor.fromJson({
        'protocol_version': gatewayProtocolVersion,
        'hardware_revision': 'contract-fixture',
        'firmware_version': 'contract-only',
        'boot_id': 'fixture-boot',
        'physical_tx_interlock': true,
        'interfaces': [
          {
            'type': 'can',
            'isolated': true,
            'listen_only_capable': true,
            'bitrates': [125000, 250000, 500000, 1000000, 833333],
          },
        ],
      }).interfaces.single;
      expect(unvalidatedCustom.supportsBitrate(833333), isFalse);
      expect(
        () => GatewayDescriptor.fromJson({
          'protocol_version': gatewayProtocolVersion,
          'hardware_revision': 'contract-fixture',
          'firmware_version': 'contract-only',
          'boot_id': 'fixture-boot',
          'physical_tx_interlock': true,
          'interfaces': [
            {
              'type': 'can',
              'isolated': true,
              'listen_only_capable': true,
              'bitrates': [500000],
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('high-voltage battery remains passive without hardware evidence', () {
      final passive = const GatewaySessionNegotiator().negotiatePassive(
        gateway(),
        requirement,
      );
      expect(passive.mode, GatewayOperatingMode.listenOnly);
      expect(
        () => const GatewaySessionNegotiator().negotiateActiveRead(
          gateway(),
          requirement,
          capabilityStatus: VerificationStatus.verifiedDocument,
          explicitlyStarted: true,
          maxFramesPerSecond: 4,
          busLoadCap: .1,
          highVoltageBattery: true,
        ),
        throwsA(isA<GatewayContractException>()),
      );
      final verified = const GatewaySessionNegotiator().negotiateActiveRead(
        gateway(),
        requirement,
        capabilityStatus: VerificationStatus.verifiedHardware,
        explicitlyStarted: true,
        maxFramesPerSecond: 4,
        busLoadCap: .1,
        highVoltageBattery: true,
      );
      expect(verified.mode, GatewayOperatingMode.activeRead);
    });
  });

  group('gateway transmission contract', () {
    final allowList = GatewayTransmissionAllowList(
      canIdentifiers: const {0x301},
      rs485Requests: {
        const Rs485AllowListEntry(unitAddress: 1, functionCode: 3),
      },
    );
    final contract = GatewayTransmissionContract(allowList);

    test(
      'drops and marks non-allow-listed CAN and RS485 requests for audit',
      () {
        for (final request in [
          const GatewayTransmissionRequest.can(0x777),
          GatewayTransmissionRequest.rs485(unitAddress: 2, functionCode: 6),
        ]) {
          final decision = contract.evaluate(request);
          expect(decision.allowed, isFalse);
          expect(decision.dropped, isTrue);
          expect(decision.auditAction, 'tx_allowlist_drop');
        }
        expect(
          contract
              .evaluate(const GatewayTransmissionRequest.can(0x301))
              .allowed,
          isTrue,
        );
        expect(
          contract
              .evaluate(
                GatewayTransmissionRequest.rs485(
                  unitAddress: 1,
                  functionCode: 3,
                ),
              )
              .allowed,
          isTrue,
        );
        expect(contract.auditRecords, hasLength(4));
        expect(
          contract.auditRecords.where(
            (record) => record.action == 'tx_allowlist_drop',
          ),
          hasLength(2),
        );
      },
    );

    test('LinkHealth carries nullable CAN TEC REC and bus-off evidence', () {
      const health = LinkHealth(
        latency: Duration(milliseconds: 8),
        errorRate: 0,
        timeouts: 0,
        crcFailures: 0,
        canTransmitErrorCounter: 3,
        canReceiveErrorCounter: 5,
        canBusOff: false,
      );
      expect(health.canTransmitErrorCounter, 3);
      expect(health.canReceiveErrorCounter, 5);
      expect(health.canBusOff, isFalse);
    });
  });

  test('research targets contain metadata only for all requested vendors', () {
    expect(
      inverterResearchTargets.map((target) => target.manufacturer).toSet(),
      {'Sungrow', 'Deye', 'Growatt', 'Horizon', 'Felicity Solar', 'Voltronic'},
    );
    expect(
      batteryResearchTargets.map((target) => target.manufacturer).toSet(),
      {
        'Pylontech',
        'Dyness',
        'Felicity Lithium',
        'Growatt ARK',
        'Deye Lithium',
        'JK BMS',
        'JBD',
        'Daly',
        'Seplos',
      },
    );
    expect(
      researchTargets.every(
        (target) => target.status == VerificationStatus.researchTarget,
      ),
      isTrue,
    );
  });

  group('gateway wire protocol', () {
    const codec = GatewayMessageCodec();

    test('round-trips a bounded typed message', () {
      const original = GatewayMessage(
        sequence: 7,
        type: 'hello',
        payload: {'protocol_version': 1},
      );
      final decoded = codec.decode(codec.encode(original));
      expect(decoded.sequence, 7);
      expect(decoded.type, 'hello');
      expect(decoded.payload['protocol_version'], 1);
    });

    test('rejects malformed and oversized messages', () {
      expect(() => codec.decode('{}'), throwsFormatException);
      expect(
        () => codec.decode('x' * (maximumGatewayMessageBytes + 1)),
        throwsFormatException,
      );
    });

    test('rejects replayed and out-of-order messages', () {
      final guard = GatewaySequenceGuard();
      guard.accept(
        const GatewayMessage(sequence: 2, type: 'frame', payload: {}),
      );
      expect(
        () => guard.accept(
          const GatewayMessage(sequence: 2, type: 'frame', payload: {}),
        ),
        throwsFormatException,
      );
      expect(
        () => guard.accept(
          const GatewayMessage(sequence: 1, type: 'frame', payload: {}),
        ),
        throwsFormatException,
      );
    });
  });

  group('guard-owned frame transport', () {
    LoopbackGatewayTransport transport(GatewayOperatingMode mode) =>
        LoopbackGatewayTransport(
          mode: mode,
          guard: const TransmissionGuard(
            allowedReadIdentifiers: {0x301},
            allowedWriteIdentifiers: {},
            activeSession: true,
            profileVerifiedForHardware: false,
          ),
          maxFramesPerSecond: 1,
          busLoadCap: .1,
          audit: AuditChain(),
        );

    test('passive and disallowed frames never reach the wire', () async {
      final passive = transport(GatewayOperatingMode.listenOnly);
      await expectLater(
        passive.send(
          const BusFrame(identifier: 0x301, payload: []),
          TransmissionPurpose.documentedRead,
        ),
        throwsStateError,
      );
      expect(passive.wire, isEmpty);
      final active = transport(GatewayOperatingMode.activeRead);
      await expectLater(
        active.send(
          const BusFrame(identifier: 0x777, payload: []),
          TransmissionPurpose.documentedRead,
        ),
        throwsStateError,
      );
      expect(active.wire, isEmpty);
    });

    test('rate cap backs off and transitions are auditable', () async {
      final active = transport(GatewayOperatingMode.activeRead);
      await active.send(
        const BusFrame(identifier: 0x301, payload: []),
        TransmissionPurpose.documentedRead,
      );
      await expectLater(
        active.send(
          const BusFrame(identifier: 0x301, payload: []),
          TransmissionPurpose.documentedRead,
        ),
        throwsStateError,
      );
      expect(active.wire, hasLength(1));
      expect(
        active.audit.entries.map((entry) => entry.action),
        containsAll(['gateway_mode_started', 'frame_sent', 'frame_backoff']),
      );
    });

    test('error frame forces back-off before the next send', () async {
      final active = transport(GatewayOperatingMode.activeRead);
      active.receive(const BusFrame(identifier: 0, payload: [], isError: true));
      await expectLater(
        active.send(
          const BusFrame(identifier: 0x301, payload: []),
          TransmissionPurpose.documentedRead,
        ),
        throwsStateError,
      );
      expect(active.wire, isEmpty);
      expect(
        active.audit.entries.map((entry) => entry.action),
        contains('gateway_error_backoff'),
      );
    });
  });
}
