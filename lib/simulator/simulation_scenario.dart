import '../core/battery_models.dart';

enum SimulationScenario {
  healthy,
  gradualImbalance,
  highTemperature,
  electricalEvents,
  balancing,
  communicationFaults,
  parallelBank,
  masterSlaveMisconfiguration,
  inverterPeer,
  parameterProfile,
  identityMismatch,
}

class SimulatedModule implements ModuleStatus {
  const SimulatedModule({
    required this.address,
    required this.role,
    required this.soc,
    required this.current,
  });
  @override
  final int address;
  @override
  final String role;
  @override
  final double soc;
  @override
  final double current;
}

class ScenarioFrame {
  const ScenarioFrame({
    required this.snapshot,
    required this.alarmCodes,
    required this.linkAvailable,
    required this.modules,
    required this.metadata,
  });
  final TelemetrySnapshot snapshot;
  final Set<String> alarmCodes;
  final bool linkAvailable;
  final List<SimulatedModule> modules;
  final Map<String, Object> metadata;
}

abstract final class ScenarioFactory {
  static ScenarioFrame create(SimulationScenario scenario, {int tick = 0}) {
    final time = DateTime.utc(2026, 1, 1).add(Duration(seconds: tick));
    Measurement value(
      double number,
      String unit, {
      MeasurementQuality quality = MeasurementQuality.good,
    }) => Measurement.value(number, unit, timestamp: time, quality: quality);
    Measurement absent(String unit, DataAbsenceReason reason) =>
        Measurement.absent(reason, unit: unit, timestamp: time);
    final cellValues = List<double>.generate(
      16,
      (index) => 3.200 + ((index + tick) % 5) * .001,
    );
    if (scenario == SimulationScenario.gradualImbalance) {
      cellValues[7] += .010 + tick * .005;
    }
    if (scenario == SimulationScenario.electricalEvents) {
      cellValues[3] = tick.isEven ? 3.70 : 2.70;
    }
    final cells = [
      for (var i = 0; i < cellValues.length; i++) value(cellValues[i], 'V'),
    ];
    final highTemperature = scenario == SimulationScenario.highTemperature;
    final communicationFault =
        scenario == SimulationScenario.communicationFaults;
    final balancing = scenario == SimulationScenario.balancing;
    final packVoltage = cellValues.fold<double>(0, (sum, cell) => sum + cell);
    final current = scenario == SimulationScenario.electricalEvents
        ? 145.0
        : -8.6 + (tick % 4) * .1;
    final missingTemperature = communicationFault && tick % 3 == 2;
    final modules = scenario == SimulationScenario.parallelBank
        ? const [
            SimulatedModule(address: 1, role: 'master', soc: 80, current: -3.0),
            SimulatedModule(address: 2, role: 'slave', soc: 78, current: -2.8),
            SimulatedModule(address: 2, role: 'slave', soc: 61, current: -0.4),
          ]
        : scenario == SimulationScenario.masterSlaveMisconfiguration
        ? const [
            SimulatedModule(address: 1, role: 'master', soc: 78, current: -4),
            SimulatedModule(address: 2, role: 'master', soc: 78, current: -4),
          ]
        : const <SimulatedModule>[];
    return ScenarioFrame(
      snapshot: TelemetrySnapshot(
        voltage: value(packVoltage, 'V'),
        current: value(current, 'A'),
        power: value(packVoltage * current, 'W'),
        soc: value(78 - (tick % 5).toDouble(), '%'),
        soh: absent('%', DataAbsenceReason.notReported),
        remainingCapacity: value(78, 'Ah'),
        fullChargeCapacity: value(100, 'Ah'),
        cycleCount: value(214, 'cycles'),
        cellMeasurements: List.unmodifiable(cells),
        temperatureSensors: [
          TemperatureReading(
            label: 'Cell 1',
            kind: TemperatureSensorKind.cell,
            measurement: missingTemperature
                ? absent('°C', DataAbsenceReason.readFailed)
                : value(
                    highTemperature ? 63 : 27 + (tick % 3).toDouble(),
                    '°C',
                  ),
          ),
          TemperatureReading(
            label: 'MOSFET',
            kind: TemperatureSensorKind.mosfet,
            measurement: value(highTemperature ? 48 : 29, '°C'),
          ),
          TemperatureReading(
            label: 'Ambient',
            kind: TemperatureSensorKind.ambient,
            measurement: value(25, '°C'),
          ),
        ],
        chargeMosfet: value(1, 'state'),
        dischargeMosfet: value(1, 'state'),
        contactor: value(1, 'state'),
        balancingMask: value(balancing ? 0x002d : 0, 'bitmask'),
        chargeCurrentLimit: value(100, 'A'),
        dischargeCurrentLimit: value(120, 'A'),
        chargeVoltageLimit: value(56.8, 'V'),
        rawAlarmBits: value(
          scenario == SimulationScenario.electricalEvents
              ? 3
              : highTemperature
              ? 4
              : 0,
          'bitmask',
        ),
        rawProtectionBits: value(
          scenario == SimulationScenario.electricalEvents ? 3 : 0,
          'bitmask',
        ),
        linkStatus: communicationFault
            ? (tick.isOdd
                  ? absent('state', DataAbsenceReason.readFailed)
                  : value(1, 'state', quality: MeasurementQuality.uncertain))
            : value(1, 'state'),
        timestamp: time,
        staleAfter: const Duration(seconds: 3),
      ),
      alarmCodes: scenario == SimulationScenario.electricalEvents
          ? const {'CELL_OVERVOLTAGE', 'PACK_OVERCURRENT'}
          : highTemperature
          ? const {'CELL_OVERTEMPERATURE'}
          : const {},
      linkAvailable: !communicationFault || tick.isEven,
      modules: modules,
      metadata: {
        'simulated': true,
        if (scenario == SimulationScenario.identityMismatch)
          'connected_model': 'LFP-UNKNOWN-MISMATCH',
        if (scenario == SimulationScenario.inverterPeer)
          'peer_case': [
            'compatible',
            'limits-restricted',
            'incompatible-protocol',
          ][tick % 3],
        if (scenario == SimulationScenario.parameterProfile) ...{
          'write_failure': tick % 3 == 1,
          'readback_mismatch': tick % 3 == 2,
          'restart_required': true,
        },
        if (communicationFault) ...{
          'crc_errors': tick % 3,
          'bus_off': tick % 5 == 4,
        },
      },
    );
  }
}
