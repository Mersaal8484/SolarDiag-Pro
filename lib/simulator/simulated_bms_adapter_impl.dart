part of '../parameters/write_pipeline.dart';

class SimulatedBmsAdapter extends SimulatedParameterBackend
    implements BmsAdapter {
  SimulatedBmsAdapter({
    this.scenario = SimulationScenario.healthy,
    int initialTick = 0,
  }) : _tick = initialTick;
  final SimulationScenario scenario;
  int _tick;
  bool _mismatchPending = false;
  final Map<String, num> _parameters = {
    'charge_limit': 55.2,
    'service_mode': 1,
  };
  @override
  DeviceProfileIdentity get profileIdentity => const DeviceProfileIdentity(
    profileId: 'solardiag.simulated.lfp16.v2',
    model: 'LFP-16S-SIM',
    firmware: 'simulator-v2',
    deviceId: 'SOLARDIAG-SIM-BMS',
  );

  ScenarioFrame get frame => ScenarioFactory.create(scenario, tick: _tick);
  void advance() => _tick++;
  @override
  Future<IdentificationResult> identify() async => IdentificationResult(
    confidence: 1,
    evidence: const ['simulator:deterministic-id'],
    candidateProfileIds: [profileIdentity.profileId],
    model: scenario == SimulationScenario.identityMismatch
        ? 'LFP-UNKNOWN-MISMATCH'
        : profileIdentity.model,
    firmware: profileIdentity.firmware,
  );
  @override
  Future<TelemetrySnapshot> readTelemetry() async {
    if (!frame.linkAvailable) throw const LinkUnavailableException();
    return frame.snapshot;
  }

  @override
  Future<List<Measurement>> readCellVoltages() async =>
      List.unmodifiable((await readTelemetry()).cellMeasurements);
  @override
  Future<Set<String>> readAlarms() async => Set.unmodifiable(frame.alarmCodes);
  @override
  Future<Map<String, num>> readParameters() async =>
      Map.unmodifiable(_parameters);

  @override
  Future<num> readParameter(String id) async {
    final value = _parameters[id]!;
    if (_mismatchPending) {
      _mismatchPending = false;
      return value + 1;
    }
    return value;
  }

  @override
  Future<Map<String, num>> readConfiguration() async => Map.of(_parameters);

  @override
  Future<void> applyRawParameter(
    String id,
    int raw,
    String idempotencyKey,
  ) async {
    if (scenario == SimulationScenario.parameterProfile &&
        frame.metadata['write_failure'] == true) {
      throw StateError('Injected simulated write failure.');
    }
    _parameters[id] = raw * .1;
    _mismatchPending = frame.metadata['readback_mismatch'] == true;
  }

  @override
  ParameterTransport parameterTransport() =>
      createSimulatedParameterTransport(this);
  @override
  Future<CapabilitySet> capabilities() async => CapabilitySet({
    for (final capability in DeviceCapability.values)
      capability: VerificationStatus.simulated,
  });
  @override
  Future<LinkHealth> health() async => LinkHealth(
    latency: const Duration(milliseconds: 12),
    errorRate: scenario == SimulationScenario.communicationFaults ? .5 : 0,
    timeouts: scenario == SimulationScenario.communicationFaults ? 1 : 0,
    crcFailures: scenario == SimulationScenario.communicationFaults ? 1 : 0,
  );
}

class LinkUnavailableException implements Exception {
  const LinkUnavailableException();
  @override
  String toString() =>
      'Simulated link is unavailable for this deterministic tick.';
}
