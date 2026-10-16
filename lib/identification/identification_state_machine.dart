import '../protocol/bms_adapter.dart';
import '../protocol/device_profile.dart';
import '../transport/safe_frame_transport.dart';

enum IdentificationState {
  idle,
  detectGateway,
  enumerateInterfaces,
  passiveObserve,
  selectCandidates,
  safeQuery,
  parseIdentity,
  matchProfile,
  confirm,
  ambiguous,
  unsupported,
  failed,
}

class GatewayObservation {
  const GatewayObservation({
    required this.available,
    required this.interfaces,
    required this.observedIdentifiers,
  });
  final bool available;
  final Set<InterfaceType> interfaces;
  final Set<int> observedIdentifiers;
}

class IdentificationOutcome {
  const IdentificationOutcome({
    required this.state,
    required this.profile,
    required this.evidence,
    this.message,
  });
  final IdentificationState state;
  final DeviceProfile? profile;
  final List<String> evidence;
  final String? message;
  bool get confirmed => state == IdentificationState.confirm;
}

typedef ReadOnlyQuery = Future<IdentificationResult> Function(BusFrame frame);

class IdentificationStateMachine {
  IdentificationStateMachine({required this.profiles, required this.query});
  final List<DeviceProfile> profiles;
  final ReadOnlyQuery query;
  final List<IdentificationState> _history = [IdentificationState.idle];
  List<IdentificationState> get history => List.unmodifiable(_history);

  Future<IdentificationOutcome> run(GatewayObservation gateway) async {
    _move(IdentificationState.detectGateway);
    if (!gateway.available) {
      return _finish(
        IdentificationState.failed,
        null,
        const [],
        'Gateway is unavailable.',
      );
    }
    _move(IdentificationState.enumerateInterfaces);
    _move(IdentificationState.passiveObserve);
    final candidates = profiles
        .where(
          (profile) =>
              gateway.interfaces.contains(profile.transport.interfaceType),
        )
        .toList();
    _move(IdentificationState.selectCandidates);
    if (candidates.isEmpty) {
      return _finish(
        IdentificationState.unsupported,
        null,
        const [],
        'No profile matches the observed interface.',
      );
    }
    final passiveMatches = candidates
        .where(
          (profile) => profile.allowedReadFrames.any(
            gateway.observedIdentifiers.contains,
          ),
        )
        .toList();
    if (passiveMatches.length == 1) {
      return _finish(IdentificationState.confirm, passiveMatches.single, const [
        'passive-frame-match',
      ]);
    }

    final evidence = <String>[];
    final identified = <DeviceProfile>[];
    for (final profile in candidates) {
      if (profile.allowedReadFrames.isEmpty) continue;
      final identifier = profile.allowedReadFrames.first;
      final guard = TransmissionGuard(
        allowedReadIdentifiers: profile.allowedReadFrames,
        allowedWriteIdentifiers: const {},
        activeSession: true,
        profileVerifiedForHardware: false,
      );
      final frame = BusFrame(identifier: identifier, payload: const []);
      if (!guard.evaluate(frame, TransmissionPurpose.documentedRead).allowed) {
        continue;
      }
      _move(IdentificationState.safeQuery);
      final result = await query(frame);
      _move(IdentificationState.parseIdentity);
      evidence.addAll(result.evidence);
      if (result.candidateProfileIds.contains(profile.id) &&
          result.confidence >= .9) {
        identified.add(profile);
      }
    }
    _move(IdentificationState.matchProfile);
    if (identified.length == 1) {
      return _finish(IdentificationState.confirm, identified.single, evidence);
    }
    if (identified.length > 1) {
      return _finish(
        IdentificationState.ambiguous,
        null,
        evidence,
        'Multiple profiles match; user confirmation is required.',
      );
    }
    return _finish(
      IdentificationState.unsupported,
      null,
      evidence,
      'No verified profile matched the identity response.',
    );
  }

  void _move(IdentificationState state) => _history.add(state);
  IdentificationOutcome _finish(
    IdentificationState state,
    DeviceProfile? profile,
    List<String> evidence, [
    String? message,
  ]) {
    _move(state);
    return IdentificationOutcome(
      state: state,
      profile: profile,
      evidence: List.unmodifiable(evidence),
      message: message,
    );
  }
}
