import '../core/battery_models.dart';
import 'diagnostic_models.dart';

class DiagnosticThresholds {
  const DiagnosticThresholds({
    this.cellAttentionVolts = .030,
    this.cellWarningVolts = .050,
    this.temperatureWarningCelsius = 50,
    this.temperatureCriticalCelsius = 60,
  });
  final double cellAttentionVolts;
  final double cellWarningVolts;
  final double temperatureWarningCelsius;
  final double temperatureCriticalCelsius;
}

class BatteryDiagnostics {
  const BatteryDiagnostics({this.thresholds = const DiagnosticThresholds()});
  final DiagnosticThresholds thresholds;

  HealthAssessment analyze(
    BatterySnapshot snapshot, {
    Set<String> rawAlarmCodes = const {},
  }) {
    final findings = <DiagnosticFinding>[
      _cellBalance(snapshot),
      _temperature(snapshot),
      ...rawAlarmCodes.map(FaultInterpreter.interpret),
    ];
    return HealthAssessment(
      stateOfHealth: null,
      reason: 'SOH_NOT_REPORTED_OR_DERIVABLE',
      findings: List.unmodifiable(findings),
    );
  }

  DiagnosticFinding _cellBalance(BatterySnapshot snapshot) {
    final delta = snapshot.cellDelta;
    if (delta == null) {
      return const DiagnosticFinding(
        code: 'CELL_DELTA_UNAVAILABLE',
        severity: DiagnosticSeverity.info,
        titleKey: 'cell_data_unavailable',
        detailKey: 'cell_data_unavailable_detail',
        evidence: {},
        confidence: DiagnosticConfidence.unavailable,
      );
    }
    final min = snapshot.cellVoltages.reduce((a, b) => a < b ? a : b);
    final max = snapshot.cellVoltages.reduce((a, b) => a > b ? a : b);
    final severity = delta >= thresholds.cellWarningVolts
        ? DiagnosticSeverity.warning
        : delta >= thresholds.cellAttentionVolts
        ? DiagnosticSeverity.attention
        : DiagnosticSeverity.info;
    return DiagnosticFinding(
      code: 'CELL_DELTA',
      severity: severity,
      titleKey: severity == DiagnosticSeverity.info
          ? 'cells_balanced'
          : 'cell_imbalance',
      detailKey: severity == DiagnosticSeverity.info
          ? 'cells_balanced_detail'
          : 'cell_imbalance_detail',
      evidence: {
        'delta_v': delta,
        'min_v': min,
        'max_v': max,
        'cell_count': snapshot.cellVoltages.length,
      },
      confidence: DiagnosticConfidence.high,
    );
  }

  DiagnosticFinding _temperature(BatterySnapshot snapshot) {
    final value = snapshot.temperature.value;
    if (value == null) {
      return DiagnosticFinding(
        code: 'TEMPERATURE_UNAVAILABLE',
        severity: DiagnosticSeverity.info,
        titleKey: 'temperature_unavailable',
        detailKey: 'temperature_unavailable_detail',
        evidence: {
          'reason': snapshot.temperature.absenceReason?.name ?? 'unknown',
        },
        confidence: DiagnosticConfidence.unavailable,
      );
    }
    final severity = value >= thresholds.temperatureCriticalCelsius
        ? DiagnosticSeverity.critical
        : value >= thresholds.temperatureWarningCelsius
        ? DiagnosticSeverity.warning
        : DiagnosticSeverity.info;
    return DiagnosticFinding(
      code: 'PACK_TEMPERATURE',
      severity: severity,
      titleKey: severity == DiagnosticSeverity.info
          ? 'temperature_normal'
          : 'temperature_high',
      detailKey: severity == DiagnosticSeverity.info
          ? 'temperature_normal_detail'
          : 'temperature_high_detail',
      evidence: {'temperature_c': value},
      confidence: DiagnosticConfidence.high,
    );
  }
}

abstract final class FaultInterpreter {
  static const _known = <String, (DiagnosticSeverity, String, String)>{
    'CELL_OVERVOLTAGE': (
      DiagnosticSeverity.critical,
      'cell_overvoltage',
      'cell_overvoltage_detail',
    ),
    'CELL_UNDERVOLTAGE': (
      DiagnosticSeverity.critical,
      'cell_undervoltage',
      'cell_undervoltage_detail',
    ),
    'PACK_OVERTEMPERATURE': (
      DiagnosticSeverity.critical,
      'pack_overtemperature',
      'pack_overtemperature_detail',
    ),
  };
  static DiagnosticFinding interpret(String rawCode) {
    final definition = _known[rawCode];
    if (definition == null) {
      return DiagnosticFinding(
        code: rawCode,
        severity: DiagnosticSeverity.warning,
        titleKey: 'unknown_alarm',
        detailKey: 'unknown_alarm_detail',
        evidence: {'raw_code': rawCode},
        confidence: DiagnosticConfidence.low,
      );
    }
    return DiagnosticFinding(
      code: rawCode,
      severity: definition.$1,
      titleKey: definition.$2,
      detailKey: definition.$3,
      evidence: {'raw_code': rawCode},
      confidence: DiagnosticConfidence.high,
    );
  }
}
