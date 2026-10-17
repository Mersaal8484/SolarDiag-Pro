import '../core/battery_models.dart';
import '../parameters/write_pipeline.dart';
import '../protocol/bms_adapter.dart';
import '../protocol/capabilities.dart';
import 'simulation_scenario.dart';

class SimulatedBmsAdapter implements BmsAdapter {
  SimulatedBmsAdapter({this.scenario = SimulationScenario.healthy});
  final SimulationScenario scenario;
  int _tick = 0;
  bool _mismatchPending = false;
  final Map<String, num> _parameters = {
    'charge_limit': 55.2,
    'service_mode': 1,
  };
  ScenarioFrame get frame => ScenarioFactory.create(scenario, tick: _tick);
  void advance() => _tick++;
  @override
  Future<IdentificationResult> identify() async => const IdentificationResult(
    confidence: 1,
    evidence: ['simulator:deterministic-id'],
    candidateProfileIds: ['solardiag.simulated.lfp16.v1'],
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
  ParameterTransport parameterTransport() => createSimulatedParameterTransport(
    read: (id) async {
      final value = _parameters[id]!;
      if (_mismatchPending) {
        _mismatchPending = false;
        return value + 1;
      }
      return value;
    },
    readAll: () async => Map.of(_parameters),
    write: (id, raw, _) async {
      if (scenario == SimulationScenario.parameterProfile &&
          frame.metadata['write_failure'] == true) {
        throw StateError('Injected simulated write failure.');
      }
      _parameters[id] = raw * .1;
      _mismatchPending = frame.metadata['readback_mismatch'] == true;
    },
  );
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
