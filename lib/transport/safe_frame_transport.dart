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

class GuardRule {
  const GuardRule({
    required this.identifier,
    this.dlc,
    this.payloadMask,
    this.payloadExpected,
  });

  final int identifier;
  final int? dlc;
  final List<int>? payloadMask;
  final List<int>? payloadExpected;

  bool matches(BusFrame frame) {
    if (frame.identifier != identifier) return false;
    if (dlc != null && frame.payload.length != dlc) return false;
    if (payloadMask != null && payloadExpected != null) {
      if (frame.payload.length < payloadMask!.length) return false;
      for (var i = 0; i < payloadMask!.length; i++) {
        if ((frame.payload[i] & payloadMask![i]) != payloadExpected![i]) {
          return false;
        }
      }
    }
    return true;
  }
}

class TransmissionGuard {
  const TransmissionGuard({
    this.allowedReadIdentifiers = const {},
    this.allowedWriteIdentifiers = const {},
    this.readRules = const [],
    this.writeRules = const [],
    required this.activeSession,
    required this.profileVerifiedForHardware,
  });
  final Set<int> allowedReadIdentifiers;
  final Set<int> allowedWriteIdentifiers;
  final List<GuardRule> readRules;
  final List<GuardRule> writeRules;
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
      if (readRules.isNotEmpty) {
        return readRules.any((rule) => rule.matches(frame))
            ? const TransmissionDecision.allow()
            : const TransmissionDecision.deny(
                'Frame does not match read rule constraints.',
              );
      }
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
    if (writeRules.isNotEmpty) {
      return writeRules.any((rule) => rule.matches(frame))
          ? const TransmissionDecision.allow()
          : const TransmissionDecision.deny(
              'Frame does not match write rule constraints.',
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
    required TransmissionGuard guard,
    required this.maxFramesPerSecond,
    required this.busLoadCap,
    required this.audit,
    this.cooldown = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _guard = guard,
       _clock = clock ?? DateTime.now {
    audit.append('gateway_mode_started', {'mode': mode.name});
  }
  @override
  final GatewayOperatingMode mode;
  final TransmissionGuard _guard;
  final int maxFramesPerSecond;
  final double busLoadCap;
  final AuditChain audit;
  final Duration cooldown;
  final DateTime Function() _clock;
  final List<BusFrame> wire = [];
  final _controller = StreamController<BusFrame>.broadcast();
  final List<DateTime> _sentAt = [];
  final List<DateTime> _errorTimestamps = [];
  int errorCount = 0;
  int blockedCount = 0;
  bool _closed = false;

  double get observedBusLoad {
    final now = _clock();
    _errorTimestamps.removeWhere(
      (time) => now.difference(time) >= cooldown,
    );
    return _errorTimestamps.isNotEmpty ? busLoadCap : 0.0;
  }

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
      blockedCount++;
      audit.append('frame_rejected', {
        'identifier': frame.identifier,
        'reason': decision.reason,
      });
      throw StateError(decision.reason);
    }
    final now = _clock();
    _sentAt.removeWhere(
      (time) => now.difference(time) >= const Duration(seconds: 1),
    );
    if (_sentAt.length >= maxFramesPerSecond || observedBusLoad >= busLoadCap) {
      blockedCount++;
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
      errorCount++;
      _errorTimestamps.add(_clock());
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
