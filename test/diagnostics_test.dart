import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/diagnostics/battery_diagnostics.dart';
import 'package:solardiag_pro/diagnostics/diagnostic_models.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';

void main() {
  const diagnostics = BatteryDiagnostics();
  test('never invents state of health', () {
    final assessment = diagnostics.analyze(
      ScenarioFactory.create(SimulationScenario.healthy).snapshot,
    );
    expect(assessment.stateOfHealth.value, isNull);
    expect(assessment.source, DiagnosticEvidenceSource.unavailable);
    expect(assessment.reason, DataAbsenceReason.notReported);
  });
  test('reported state of health preserves timestamp and source', () {
    final soh = Measurement.value(
      96.5,
      '%',
      timestamp: DateTime.utc(2026, 10, 24),
    );
    final snapshot = _withSoh(
      ScenarioFactory.create(SimulationScenario.healthy).snapshot,
      soh,
    );
    final assessment = diagnostics.analyze(snapshot);

    expect(assessment.stateOfHealth.value, 96.5);
    expect(assessment.stateOfHealth.timestamp, soh.timestamp);
    expect(assessment.source, DiagnosticEvidenceSource.deviceReported);
    expect(assessment.reason, isNull);
  });
  test('absent state of health preserves the device absence reason', () {
    final snapshot = _withSoh(
      ScenarioFactory.create(SimulationScenario.healthy).snapshot,
      const Measurement.absent(DataAbsenceReason.readFailed, unit: '%'),
    );

    final assessment = diagnostics.analyze(snapshot);

    expect(assessment.stateOfHealth.value, isNull);
    expect(assessment.source, DiagnosticEvidenceSource.unavailable);
    expect(assessment.reason, DataAbsenceReason.readFailed);
  });
  test('detects cell imbalance from reported raw values', () {
    final assessment = diagnostics.analyze(
      ScenarioFactory.create(
        SimulationScenario.gradualImbalance,
        tick: 10,
      ).snapshot,
    );
    final finding = assessment.findings.singleWhere(
      (item) => item.code == 'CELL_DELTA',
    );
    expect(finding.severity, DiagnosticSeverity.warning);
    expect(finding.confidence, DiagnosticConfidence.high);
    expect(finding.evidence['delta_v'], greaterThan(.05));
  });
  test('absent cell voltages are explicitly unavailable', () {
    final snapshot = _withCells(
      ScenarioFactory.create(SimulationScenario.healthy).snapshot,
      const [],
    );
    final finding = diagnostics
        .analyze(snapshot, expectedCellCount: 16)
        .findings
        .singleWhere((item) => item.code == 'CELL_VOLTAGES_UNAVAILABLE');

    expect(finding.confidence, DiagnosticConfidence.unavailable);
    expect(finding.evidence['cell_count_expected'], 16);
    expect(finding.evidence['cell_count_used'], 0);
  });
  test('cell count evidence reports topology versus measured values', () {
    final snapshot = ScenarioFactory.create(
      SimulationScenario.healthy,
    ).snapshot;
    final finding = diagnostics
        .analyze(snapshot, expectedCellCount: 15)
        .findings
        .singleWhere((item) => item.code == 'CELL_COUNT_MISMATCH');

    expect(finding.evidence['cell_count_expected'], 15);
    expect(finding.evidence['cell_count_used'], snapshot.cellVoltages.length);
  });
  test('missing temperature remains unavailable', () {
    final assessment = diagnostics.analyze(
      ScenarioFactory.create(
        SimulationScenario.communicationFaults,
        tick: 2,
      ).snapshot,
    );
    final finding = assessment.findings.singleWhere(
      (item) => item.code == 'TEMPERATURE_UNAVAILABLE',
    );
    expect(finding.confidence, DiagnosticConfidence.unavailable);
    expect(finding.evidence['reason'], DataAbsenceReason.readFailed.name);
  });
  test('known raw alarm is interpreted without losing raw evidence', () {
    final assessment = diagnostics.analyze(
      ScenarioFactory.create(SimulationScenario.electricalEvents).snapshot,
      rawAlarmCodes: const {'CELL_OVERVOLTAGE'},
      faultDictionary: const {
        'CELL_OVERVOLTAGE': FaultDefinition(
          code: 'CELL_OVERVOLTAGE',
          severity: DiagnosticSeverity.critical,
          titleKey: 'cellOvervoltageAlarm',
          detailKey: 'cellOvervoltageDetail',
          suggestedChecksEn: ['Check charger limits'],
          suggestedChecksAr: ['تحقق من حدود الشاحن'],
        ),
      },
    );
    final finding = assessment.findings.singleWhere(
      (item) => item.code == 'CELL_OVERVOLTAGE',
    );
    expect(finding.severity, DiagnosticSeverity.critical);
    expect(finding.evidence['raw_code'], 'CELL_OVERVOLTAGE');
  });
  test('unknown raw alarm is preserved and never guessed', () {
    final assessment = diagnostics.analyze(
      ScenarioFactory.create(SimulationScenario.healthy).snapshot,
      rawAlarmCodes: const {'VENDOR_BIT_12'},
    );
    final finding = assessment.findings.singleWhere(
      (item) => item.code == 'VENDOR_BIT_12',
    );
    expect(finding.titleKey, 'unknown_alarm');
    expect(finding.confidence, DiagnosticConfidence.low);
  });

  test('core, diagnostics, and integration do not import simulator code', () {
    final forbiddenImport = RegExp(r'''import\s+['"][^'"]*simulator/''');
    for (final directory in [
      Directory('lib/core'),
      Directory('lib/diagnostics'),
      Directory('lib/integration'),
    ]) {
      for (final file
          in directory
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        expect(
          forbiddenImport.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
    }
  });
}

TelemetrySnapshot _withSoh(TelemetrySnapshot snapshot, Measurement soh) =>
    TelemetrySnapshot(
      voltage: snapshot.voltage,
      current: snapshot.current,
      power: snapshot.power,
      soc: snapshot.soc,
      soh: soh,
      remainingCapacity: snapshot.remainingCapacity,
      fullChargeCapacity: snapshot.fullChargeCapacity,
      cycleCount: snapshot.cycleCount,
      cellMeasurements: snapshot.cellMeasurements,
      temperatureSensors: snapshot.temperatureSensors,
      chargeMosfet: snapshot.chargeMosfet,
      dischargeMosfet: snapshot.dischargeMosfet,
      contactor: snapshot.contactor,
      balancingMask: snapshot.balancingMask,
      chargeCurrentLimit: snapshot.chargeCurrentLimit,
      dischargeCurrentLimit: snapshot.dischargeCurrentLimit,
      chargeVoltageLimit: snapshot.chargeVoltageLimit,
      rawAlarmBits: snapshot.rawAlarmBits,
      rawProtectionBits: snapshot.rawProtectionBits,
      linkStatus: snapshot.linkStatus,
      timestamp: snapshot.timestamp,
      staleAfter: snapshot.staleAfter,
    );

TelemetrySnapshot _withCells(
  TelemetrySnapshot snapshot,
  List<Measurement> cellMeasurements,
) => TelemetrySnapshot(
  voltage: snapshot.voltage,
  current: snapshot.current,
  power: snapshot.power,
  soc: snapshot.soc,
  soh: snapshot.soh,
  remainingCapacity: snapshot.remainingCapacity,
  fullChargeCapacity: snapshot.fullChargeCapacity,
  cycleCount: snapshot.cycleCount,
  cellMeasurements: cellMeasurements,
  temperatureSensors: snapshot.temperatureSensors,
  chargeMosfet: snapshot.chargeMosfet,
  dischargeMosfet: snapshot.dischargeMosfet,
  contactor: snapshot.contactor,
  balancingMask: snapshot.balancingMask,
  chargeCurrentLimit: snapshot.chargeCurrentLimit,
  dischargeCurrentLimit: snapshot.dischargeCurrentLimit,
  chargeVoltageLimit: snapshot.chargeVoltageLimit,
  rawAlarmBits: snapshot.rawAlarmBits,
  rawProtectionBits: snapshot.rawProtectionBits,
  linkStatus: snapshot.linkStatus,
  timestamp: snapshot.timestamp,
  staleAfter: snapshot.staleAfter,
);
