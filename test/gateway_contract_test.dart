import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/gateway/gateway_contract.dart';
import 'package:solardiag_pro/gateway/gateway_wire_protocol.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/transport/safe_frame_transport.dart';

void main() {
  GatewayDescriptor gateway({
    bool isolated = true,
    bool interlock = true,
    int protocolVersion = gatewayProtocolVersion,
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
        bitrates: const {125000, 250000, 500000},
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

    test('rejects protocol and bitrate mismatches', () {
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
            bitrate: 1000000,
            listenOnlyByDefault: true,
          ),
        ),
        throwsA(isA<GatewayContractException>()),
      );
    });
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
