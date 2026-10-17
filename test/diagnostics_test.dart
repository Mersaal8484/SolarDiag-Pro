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
    expect(assessment.stateOfHealth, isNull);
    expect(assessment.reason, 'SOH_NOT_REPORTED_OR_DERIVABLE');
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
          titleEn: 'Cell overvoltage',
          titleAr: 'ارتفاع جهد الخلية',
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
}
