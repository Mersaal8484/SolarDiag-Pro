import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/diagnostics/battery_diagnostics.dart';
import 'package:solardiag_pro/integration/compatibility_engine.dart';
import 'package:solardiag_pro/integration/compatibility_models.dart';
import 'package:solardiag_pro/simulator/simulated_bms_adapter.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';

void main() {
  test('all ten deterministic simulator scenarios are present', () {
    expect(SimulationScenario.values, hasLength(10));
    for (final scenario in SimulationScenario.values) {
      final first = ScenarioFactory.create(scenario, tick: 3);
      final second = ScenarioFactory.create(scenario, tick: 3);
      expect(first.snapshot.voltage.value, second.snapshot.voltage.value);
      expect(first.metadata['simulated'], isTrue);
    }
  });

  test(
    'scenario ground truth covers thermal balancing electrical and peer cases',
    () {
      expect(
        ScenarioFactory.create(
          SimulationScenario.highTemperature,
        ).snapshot.temperature.value,
        63,
      );
      expect(
        ScenarioFactory.create(
          SimulationScenario.balancing,
        ).snapshot.balancingMask.value,
        greaterThan(0),
      );
      expect(
        ScenarioFactory.create(SimulationScenario.electricalEvents).alarmCodes,
        contains('PACK_OVERCURRENT'),
      );
      expect(
        ScenarioFactory.create(
          SimulationScenario.inverterPeer,
          tick: 2,
        ).metadata['peer_case'],
        'incompatible-protocol',
      );
      expect(
        ScenarioFactory.create(
          SimulationScenario.parameterProfile,
          tick: 2,
        ).metadata['readback_mismatch'],
        isTrue,
      );
    },
  );

  test('telemetry exposes timestamped values and explicit absence', () {
    final snapshot = ScenarioFactory.create(
      SimulationScenario.healthy,
    ).snapshot;
    expect(snapshot.power.timestamp, snapshot.timestamp);
    expect(snapshot.cellMeasurements, hasLength(16));
    expect(
      snapshot.temperatureSensors.map((e) => e.label),
      containsAll(['Cell 1', 'MOSFET', 'Ambient']),
    );
    expect(snapshot.soh.value, isNull);
    expect(snapshot.soh.absenceReason, DataAbsenceReason.notReported);
    expect(snapshot.soh.timestamp, snapshot.timestamp);
  });

  test(
    'adapter exposes alarms parameters cells and pipeline-only transport',
    () async {
      final adapter = SimulatedBmsAdapter(
        scenario: SimulationScenario.electricalEvents,
      );
      expect(await adapter.readAlarms(), contains('CELL_OVERVOLTAGE'));
      expect(await adapter.readCellVoltages(), hasLength(16));
      expect((await adapter.readParameters())['charge_limit'], 55.2);
      expect(adapter.parameterTransport().kind.name, 'simulator');
    },
  );

  test(
    'advanced diagnostics compute distributions outliers parallel and diffs',
    () {
      const diagnostics = BatteryDiagnostics();
      final imbalanced = [
        for (var tick = 8; tick < 12; tick++)
          ScenarioFactory.create(
            SimulationScenario.gradualImbalance,
            tick: tick,
          ).snapshot,
      ];
      expect(
        diagnostics.cellStandardDeviation(imbalanced.last),
        greaterThan(0),
      );
      expect(diagnostics.persistentOutliers(imbalanced), contains(7));
      final temperatures = diagnostics.temperatureDistribution(
        ScenarioFactory.create(SimulationScenario.highTemperature).snapshot,
      );
      expect(temperatures.gradient, 38);
      expect(temperatures.hottestLabel, 'Cell 1');
      final parallelFrame = ScenarioFactory.create(
        SimulationScenario.parallelBank,
      );
      final parallel = diagnostics.analyzeParallel(parallelFrame.modules);
      expect(parallel.duplicateAddresses, contains(2));
      expect(parallel.socSpread, 19);
      final master = diagnostics.analyzeParallel(
        ScenarioFactory.create(
          SimulationScenario.masterSlaveMisconfiguration,
        ).modules,
      );
      expect(master.masterCount, 2);
      final diff = diagnostics.compare(
        ScenarioFactory.create(SimulationScenario.healthy, tick: 0).snapshot,
        ScenarioFactory.create(SimulationScenario.healthy, tick: 1).snapshot,
      );
      expect(diff.singleWhere((e) => e.field == 'soc').delta, -1);
      final trend = diagnostics.capacityTrend([
        ScenarioFactory.create(SimulationScenario.healthy, tick: 0).snapshot,
        ScenarioFactory.create(SimulationScenario.healthy, tick: 1).snapshot,
      ]);
      expect(trend.available, isTrue);
      expect(trend.methodNote, contains('not an SOH estimate'));
    },
  );

  test('aggregate verdicts and recommendations are data only', () {
    const battery = BatteryIntegrationProfile(
      chargeVoltageWindow: SourcedValue.reported(
        VoltageWindow(minimum: 50, maximum: 56),
        EvidenceSource.verifiedProfile,
      ),
      dischargeVoltageWindow: SourcedValue.reported(
        VoltageWindow(minimum: 44, maximum: 56),
        EvidenceSource.verifiedProfile,
      ),
      maximumChargeCurrent: SourcedValue.reported(
        100,
        EvidenceSource.verifiedProfile,
      ),
      maximumDischargeCurrent: SourcedValue.reported(
        100,
        EvidenceSource.verifiedProfile,
      ),
      chemistry: SourcedValue.reported('LFP', EvidenceSource.verifiedProfile),
      spokenProtocols: {'CAN-A'},
    );
    const inverter = InverterIntegrationProfile(
      configuredChargeVoltage: SourcedValue.reported(
        60,
        EvidenceSource.deviceReported,
      ),
      configuredLowVoltageCutoff: SourcedValue.reported(
        47,
        EvidenceSource.deviceReported,
      ),
      configuredChargeCurrent: SourcedValue.reported(
        80,
        EvidenceSource.deviceReported,
      ),
      configuredDischargeCurrent: SourcedValue.reported(
        80,
        EvidenceSource.deviceReported,
      ),
      supportedChemistries: {'LFP'},
      supportedBatteryProtocols: {'CAN-A'},
    );
    final assessment = const CompatibilityEngine().assess(
      battery: battery,
      inverter: inverter,
    );
    expect(assessment.verdict, IntegrationVerdict.incompatibleProfile);
    final recommendations = const CompatibilityEngine().recommendations(
      assessment,
    );
    expect(recommendations, isNotEmpty);
    expect(recommendations.first.menu, contains('documented'));
  });
}
