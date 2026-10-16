import '../core/battery_models.dart';
import '../protocol/bms_adapter.dart';
import '../protocol/capabilities.dart';
import 'simulation_scenario.dart';

class SimulatedBmsAdapter implements BmsAdapter {
  SimulatedBmsAdapter({this.scenario = SimulationScenario.nominal});
  final SimulationScenario scenario;
  int _tick = 0;
  ScenarioFrame get _frame => ScenarioFactory.create(scenario, tick: _tick);
  void advance() => _tick++;

  @override
  Future<IdentificationResult> identify() async => const IdentificationResult(
    confidence: 1,
    evidence: ['simulator:deterministic-id'],
    candidateProfileIds: ['solardiag.simulated.lfp16.v1'],
  );
  @override
  Future<BatterySnapshot> readTelemetry() async {
    if (!_frame.linkAvailable) throw const LinkUnavailableException();
    return _frame.snapshot;
  }

  @override
  Future<List<double>> readCellVoltages() async =>
      List.unmodifiable((await readTelemetry()).cellVoltages);
  @override
  Future<CapabilitySet> capabilities() async => CapabilitySet({
    DeviceCapability.identify: VerificationStatus.simulated,
    DeviceCapability.readLive: VerificationStatus.simulated,
    DeviceCapability.readConfiguration: VerificationStatus.simulated,
    DeviceCapability.writeParameter: VerificationStatus.simulated,
  });
  @override
  Future<LinkHealth> health() async => LinkHealth(
    latency: const Duration(milliseconds: 12),
    errorRate: scenario == SimulationScenario.intermittentLink ? .5 : 0,
    timeouts: scenario == SimulationScenario.intermittentLink ? 1 : 0,
    crcFailures: 0,
  );
}

class LinkUnavailableException implements Exception {
  const LinkUnavailableException();
  @override
  String toString() =>
      'Simulated link is unavailable for this deterministic tick.';
}
