import '../core/battery_models.dart';
import '../simulator/simulation_scenario.dart';

class SimulatedBms {
  const SimulatedBms();
  BatterySnapshot snapshot() =>
      ScenarioFactory.create(SimulationScenario.missingTemperature).snapshot;
}
