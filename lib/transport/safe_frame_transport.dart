import 'dart:async';
import '../audit/audit_chain.dart';
import '../gateway/gateway_contract.dart';

class BusFrame {
  const BusFrame({
    required this.identifier,
    required this.payload,
    this.isError = false,
  });
  final int identifier;
  final List<int> payload;
  final bool isError;
}

enum TransmissionPurpose { documentedRead, verifiedParameterWrite }

class TransmissionDecision {
  const TransmissionDecision._(this.allowed, this.reason);
  const TransmissionDecision.allow() : this._(true, 'allowed');
  const TransmissionDecision.deny(String reason) : this._(false, reason);
  final bool allowed;
  final String reason;
}

class TransmissionGuard {
  const TransmissionGuard({
    required this.allowedReadIdentifiers,
    required this.allowedWriteIdentifiers,
    required this.activeSession,
    required this.profileVerifiedForHardware,
  });
  final Set<int> allowedReadIdentifiers;
  final Set<int> allowedWriteIdentifiers;
  final bool activeSession;
  final bool profileVerifiedForHardware;
  TransmissionDecision evaluate(BusFrame frame, TransmissionPurpose purpose) {
    if (!activeSession) {
      return const TransmissionDecision.deny('No active diagnostic session.');
    }
    if (frame.payload.length > 8) {
      return const TransmissionDecision.deny(
        'Classic CAN payload exceeds 8 bytes.',
      );
    }
    if (purpose == TransmissionPurpose.documentedRead) {
      return allowedReadIdentifiers.contains(frame.identifier)
          ? const TransmissionDecision.allow()
          : const TransmissionDecision.deny(
              'Frame is not in the read allow-list.',
            );
    }
    if (!profileVerifiedForHardware) {
      return const TransmissionDecision.deny(
        'Write capability is not verified on hardware.',
      );
    }
    return allowedWriteIdentifiers.contains(frame.identifier)
        ? const TransmissionDecision.allow()
        : const TransmissionDecision.deny(
            'Frame is not in the verified write allow-list.',
          );
  }
}

abstract interface class FrameTransport {
  GatewayOperatingMode get mode;
  Stream<BusFrame> get frames;
  Future<void> send(BusFrame frame, TransmissionPurpose purpose);
  Future<void> close();
}

class LoopbackGatewayTransport implements FrameTransport {
  LoopbackGatewayTransport({
    required this.mode,
    required this._guard,
    required this.maxFramesPerSecond,
    required this.busLoadCap,
    required this.audit,
  }) {
    audit.append('gateway_mode_started', {'mode': mode.name});
  }
  @override
  final GatewayOperatingMode mode;
  final TransmissionGuard _guard;
  final int maxFramesPerSecond;
  final double busLoadCap;
  final AuditChain audit;
  final List<BusFrame> wire = [];
  final _controller = StreamController<BusFrame>.broadcast();
  final List<DateTime> _sentAt = [];
  double observedBusLoad = 0;
  bool _closed = false;
  @override
  Stream<BusFrame> get frames => _controller.stream;

  @override
  Future<void> send(BusFrame frame, TransmissionPurpose purpose) async {
    if (_closed) throw StateError('Transport is closed.');
    if (mode == GatewayOperatingMode.listenOnly) {
      throw StateError('Passive mode cannot transmit.');
    }
    if (mode == GatewayOperatingMode.activeRead &&
        purpose != TransmissionPurpose.documentedRead) {
      throw StateError('Active-read mode cannot write.');
    }
    final decision = _guard.evaluate(frame, purpose);
    if (!decision.allowed) {
      audit.append('frame_rejected', {
        'identifier': frame.identifier,
        'reason': decision.reason,
      });
      throw StateError(decision.reason);
    }
    final now = DateTime.now();
    _sentAt.removeWhere(
      (time) => now.difference(time) >= const Duration(seconds: 1),
    );
    if (_sentAt.length >= maxFramesPerSecond || observedBusLoad >= busLoadCap) {
      audit.append('frame_backoff', {'identifier': frame.identifier});
      throw StateError('Gateway rate or bus-load cap reached.');
    }
    _sentAt.add(now);
    wire.add(frame);
    audit.append('frame_sent', {
      'identifier': frame.identifier,
      'purpose': purpose.name,
    });
  }

  void receive(BusFrame frame) {
    if (frame.isError) {
      observedBusLoad = busLoadCap;
      audit.append('gateway_error_backoff', {'identifier': frame.identifier});
    }
    if (!_closed) {
      _controller.add(frame);
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _controller.close();
  }
}
