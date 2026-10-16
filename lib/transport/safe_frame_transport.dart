class BusFrame {
  const BusFrame({required this.identifier, required this.payload});
  final int identifier;
  final List<int> payload;
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
