import '../core/battery_models.dart';
import '../protocol/bms_adapter.dart';
import '../protocol/inverter_adapter.dart';
import '../simulator/simulated_bms_adapter.dart';
import '../simulator/simulated_inverter_adapter.dart';
import '../simulator/simulation_scenario.dart';

export '../simulator/simulation_scenario.dart' show SimulationScenario;

/// The application composition boundary for the deterministic simulator.
///
/// Safety-critical session and protocol libraries depend on adapter contracts;
/// only this composition layer knows the concrete simulator implementations.
abstract final class SimulatorRuntime {
  static BmsAdapter createBms(
    SimulationScenario scenario, {
    required int initialTick,
  }) => SimulatedBmsAdapter(scenario: scenario, initialTick: initialTick);

  static InverterAdapter createInverter() => SimulatedInverterAdapter();

  static TelemetrySnapshot initialSnapshot(
    SimulationScenario scenario, {
    required int initialTick,
  }) => ScenarioFactory.create(scenario, tick: initialTick).snapshot;
}
