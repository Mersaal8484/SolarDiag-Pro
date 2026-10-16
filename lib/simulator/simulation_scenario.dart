import '../core/battery_models.dart';

enum SimulationScenario {
  nominal,
  imbalancedCells,
  activeAlarm,
  intermittentLink,
  missingTemperature,
}

class ScenarioFrame {
  const ScenarioFrame({
    required this.snapshot,
    required this.alarmCodes,
    required this.linkAvailable,
  });
  final BatterySnapshot snapshot;
  final Set<String> alarmCodes;
  final bool linkAvailable;
}

abstract final class ScenarioFactory {
  static ScenarioFrame create(SimulationScenario scenario, {int tick = 0}) {
    final nominalCells = List<double>.generate(
      16,
      (index) => 3.200 + ((index + tick) % 5) * .001,
    );
    final cells = [...nominalCells];
    if (scenario == SimulationScenario.imbalancedCells) {
      cells[7] = 3.255;
    }
    final temperature = scenario == SimulationScenario.missingTemperature
        ? const Measurement.absent(DataAbsenceReason.notReported)
        : Measurement.value(27 + (tick % 3), '°C');
    return ScenarioFrame(
      snapshot: BatterySnapshot(
        voltage: Measurement.value(
          cells.fold<double>(0, (sum, cell) => sum + cell),
          'V',
        ),
        current: Measurement.value(-8.6 + (tick % 4) * .1, 'A'),
        soc: Measurement.value(78 - (tick % 5), '%'),
        temperature: temperature,
        cellVoltages: List.unmodifiable(cells),
        timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: tick)),
      ),
      alarmCodes: scenario == SimulationScenario.activeAlarm
          ? const {'CELL_OVERVOLTAGE'}
          : const {},
      linkAvailable:
          scenario != SimulationScenario.intermittentLink || tick.isEven,
    );
  }
}
