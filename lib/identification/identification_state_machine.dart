import 'dart:async';
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
  needsConfirmation,
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
    this.payloadFingerprintProfileIds = const {},
  });
  final bool available;
  final Set<InterfaceType> interfaces;
  final Set<int> observedIdentifiers;
  final Set<String> payloadFingerprintProfileIds;
}

class IdentificationOutcome {
  const IdentificationOutcome({
    required this.state,
    required this.profile,
    required this.evidence,
    required this.manuallySelected,
    this.message,
  });
  final IdentificationState state;
  final DeviceProfile? profile;
  final List<String> evidence;
  final bool manuallySelected;
  final String? message;
  bool get confirmed => state == IdentificationState.confirm;
}

typedef IdentityResponseParser =
    Future<IdentificationResult> Function(BusFrame frame);

class IdentificationStateMachine {
  IdentificationStateMachine({
    required this.profiles,
    required this.transport,
    required this.parseResponse,
    this.queryTimeout = const Duration(milliseconds: 500),
    this.maxRetries = 2,
    this.globalBudget = const Duration(seconds: 3),
  });
  final List<DeviceProfile> profiles;
  final FrameTransport transport;
  final IdentityResponseParser parseResponse;
  final Duration queryTimeout;
  final int maxRetries;
  final Duration globalBudget;
  final List<IdentificationState> _history = [IdentificationState.idle];
  List<IdentificationState> get history => List.unmodifiable(_history);

  IdentificationOutcome selectManually({
    required String manufacturer,
    required String family,
    required String model,
    required String firmware,
  }) {
    final matches = profiles
        .where(
          (p) =>
              p.manufacturer == manufacturer &&
              p.family == family &&
              p.models.contains(model) &&
              p.firmwareRanges.contains(firmware),
        )
        .toList();
    if (matches.length != 1) {
      return _finish(
        IdentificationState.unsupported,
        null,
        const [],
        false,
        'Manual selection did not exactly match one profile.',
      );
    }
    return _finish(
      IdentificationState.confirm,
      matches.single,
      const ['manual-selection'],
      true,
      'Manual selection can produce incorrect decoding if the device identity is wrong.',
    );
  }

  Future<IdentificationOutcome> run(GatewayObservation gateway) async {
    final deadline = DateTime.now().add(globalBudget);
    _move(IdentificationState.detectGateway);
    if (!gateway.available) {
      return _finish(
        IdentificationState.failed,
        null,
        const [],
        false,
        'Gateway is unavailable.',
      );
    }
    _move(IdentificationState.enumerateInterfaces);
    _move(IdentificationState.passiveObserve);
    final candidates = profiles
        .where((p) => gateway.interfaces.contains(p.transport.interfaceType))
        .toList();
    _move(IdentificationState.selectCandidates);
    if (candidates.isEmpty) {
      return _finish(
        IdentificationState.unsupported,
        null,
        const [],
        false,
        'No profile matches the observed interface.',
      );
    }
    final scored = <DeviceProfile, List<String>>{};
    for (final profile in candidates) {
      final evidence = <String>[];
      if (profile.allowedReadFrames.any(gateway.observedIdentifiers.contains)) {
        evidence.add('identifier-fingerprint');
      }
      if (gateway.payloadFingerprintProfileIds.contains(profile.id)) {
        evidence.add('payload-structure-periodicity');
      }
      if (evidence.isNotEmpty) scored[profile] = evidence;
    }
    final passiveConfirmed = scored.entries
        .where((e) {
          if (e.value.length < 2) return false;
          // Minimum evidence weight calculation
          var totalWeight = 0.0;
          for (final ev in e.value) {
            totalWeight += switch (ev) {
              'identifier-fingerprint' => 0.4,
              'payload-structure-periodicity' => 0.5,
              'documented-identity-response' => 0.7,
              _ => 0.3,
            };
          }
          return totalWeight >= 0.8;
        })
        .toList();
    if (passiveConfirmed.length == 1) {
      return _finish(
        IdentificationState.confirm,
        passiveConfirmed.single.key,
        passiveConfirmed.single.value,
        false,
      );
    }
    if (passiveConfirmed.length > 1) {
      return _finish(
        IdentificationState.ambiguous,
        null,
        passiveConfirmed.expand((e) => e.value).toList(),
        false,
        'Multiple profiles match independent passive evidence.',
      );
    }
    if (scored.length == 1) {
      return _finish(
        IdentificationState.needsConfirmation,
        scored.keys.single,
        scored.values.single,
        false,
        'One passive evidence type is insufficient for auto-confirmation.',
      );
    }

    final identified = <DeviceProfile>[];
    final allEvidence = <String>[];
    for (final profile in candidates) {
      if (profile.allowedReadFrames.isEmpty ||
          DateTime.now().isAfter(deadline)) {
        break;
      }
      final frame = BusFrame(
        identifier: profile.allowedReadFrames.first,
        payload: const [],
      );
      for (
        var attempt = 0;
        attempt <= maxRetries && DateTime.now().isBefore(deadline);
        attempt++
      ) {
        try {
          _move(IdentificationState.safeQuery);
          await transport.send(frame, TransmissionPurpose.documentedRead);
          final result = await parseResponse(frame).timeout(queryTimeout);
          _move(IdentificationState.parseIdentity);
          allEvidence.addAll(result.evidence);
          if (result.candidateProfileIds.contains(profile.id) &&
              result.evidence.isNotEmpty) {
            identified.add(profile);
          }
          break;
        } on TimeoutException {
          allEvidence.add('query-timeout-${attempt + 1}');
        } catch (error) {
          allEvidence.add('query-failed-${attempt + 1}:$error');
        }
      }
    }
    _move(IdentificationState.matchProfile);
    if (identified.length == 1) {
      return _finish(
        IdentificationState.confirm,
        identified.single,
        {...allEvidence, 'documented-identity-response'}.toList(),
        false,
      );
    }
    if (identified.length > 1) {
      return _finish(
        IdentificationState.ambiguous,
        null,
        allEvidence,
        false,
        'Multiple profiles match; user confirmation is required.',
      );
    }
    return _finish(
      IdentificationState.unsupported,
      null,
      allEvidence,
      false,
      'No verified profile matched the identity response.',
    );
  }

  void _move(IdentificationState state) => _history.add(state);
  IdentificationOutcome _finish(
    IdentificationState state,
    DeviceProfile? profile,
    List<String> evidence,
    bool manual, [
    String? message,
  ]) {
    _move(state);
    return IdentificationOutcome(
      state: state,
      profile: profile,
      evidence: List.unmodifiable(evidence),
      manuallySelected: manual,
      message: message,
    );
  }
}
