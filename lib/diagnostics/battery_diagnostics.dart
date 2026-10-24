import 'dart:math' as math;

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
    Map<String, FaultDefinition> faultDictionary = const {},
    int? expectedCellCount,
  }) {
    final findings = <DiagnosticFinding>[
      ..._cellBalance(snapshot, expectedCellCount),
      _temperature(snapshot),
      ...rawAlarmCodes.map(
        (code) => FaultInterpreter.interpret(code, faultDictionary),
      ),
    ];
    final stateOfHealth = snapshot.soh;
    return HealthAssessment(
      stateOfHealth: stateOfHealth,
      source: stateOfHealth.isReported
          ? DiagnosticEvidenceSource.deviceReported
          : DiagnosticEvidenceSource.unavailable,
      reason: stateOfHealth.absenceReason,
      findings: List.unmodifiable(findings),
    );
  }

  List<DiagnosticFinding> _cellBalance(
    BatterySnapshot snapshot,
    int? expectedCellCount,
  ) {
    final cells = snapshot.cellVoltages;
    final countEvidence = <String, Object?>{
      'cell_count_expected': expectedCellCount,
      'cell_count_used': cells.length,
    };
    final findings = <DiagnosticFinding>[];
    final delta = snapshot.cellDelta;
    if (delta == null) {
      findings.add(
        DiagnosticFinding(
          code: 'CELL_VOLTAGES_UNAVAILABLE',
          severity: DiagnosticSeverity.info,
          titleKey: 'cellVoltagesUnavailable',
          detailKey: 'cellVoltagesUnavailableDetail',
          evidence: countEvidence,
          confidence: DiagnosticConfidence.unavailable,
        ),
      );
    } else {
      final min = cells.reduce((a, b) => a < b ? a : b);
      final max = cells.reduce((a, b) => a > b ? a : b);
      final severity = delta >= thresholds.cellWarningVolts
          ? DiagnosticSeverity.warning
          : delta >= thresholds.cellAttentionVolts
          ? DiagnosticSeverity.attention
          : DiagnosticSeverity.info;
      findings.add(
        DiagnosticFinding(
          code: 'CELL_DELTA',
          severity: severity,
          titleKey: severity == DiagnosticSeverity.info
              ? 'cells_balanced'
              : 'cell_imbalance',
          detailKey: severity == DiagnosticSeverity.info
              ? 'cells_balanced_detail'
              : 'cell_imbalance_detail',
          evidence: {
            ...countEvidence,
            'delta_v': delta,
            'min_v': min,
            'max_v': max,
          },
          confidence: DiagnosticConfidence.high,
        ),
      );
    }
    if (expectedCellCount != null &&
        cells.isNotEmpty &&
        expectedCellCount != cells.length) {
      findings.add(
        DiagnosticFinding(
          code: 'CELL_COUNT_MISMATCH',
          severity: DiagnosticSeverity.attention,
          titleKey: 'cellCountMismatch',
          detailKey: 'cellCountMismatchDetail',
          evidence: countEvidence,
          confidence: DiagnosticConfidence.medium,
        ),
      );
    }
    return findings;
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
  static DiagnosticFinding interpret(
    String rawCode,
    Map<String, FaultDefinition> dictionary,
  ) {
    final definition = dictionary[rawCode];
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
      severity: definition.severity,
      titleKey: definition.titleKey,
      detailKey: definition.detailKey,
      evidence: {
        'raw_code': rawCode,
        'checks_en': definition.suggestedChecksEn.join('|'),
        'checks_ar': definition.suggestedChecksAr.join('|'),
      },
      confidence: DiagnosticConfidence.high,
    );
  }
}

extension CompletedBatteryDiagnostics on BatteryDiagnostics {
  double? cellStandardDeviation(TelemetrySnapshot snapshot) {
    final cells = snapshot.cellVoltages;
    if (cells.length < 2) return null;
    final mean = cells.reduce((a, b) => a + b) / cells.length;
    final variance =
        cells
            .map((value) => (value - mean) * (value - mean))
            .reduce((a, b) => a + b) /
        cells.length;
    return variance <= 0 ? 0 : math.sqrt(variance);
  }

  Set<int> persistentOutliers(
    List<TelemetrySnapshot> samples, {
    double threshold = .025,
  }) {
    if (samples.isEmpty) return const {};
    Set<int>? persistent;
    for (final sample in samples) {
      final cells = sample.cellVoltages;
      if (cells.isEmpty) return const {};
      final mean = cells.reduce((a, b) => a + b) / cells.length;
      final current = {
        for (var i = 0; i < cells.length; i++)
          if ((cells[i] - mean).abs() >= threshold) i,
      };
      persistent = persistent == null
          ? current
          : persistent.intersection(current);
    }
    return persistent ?? const {};
  }

  TemperatureDistribution temperatureDistribution(TelemetrySnapshot snapshot) {
    final available = snapshot.temperatureSensors
        .where((sensor) => sensor.measurement.value != null)
        .toList();
    if (available.isEmpty) {
      return const TemperatureDistribution(
        minimum: null,
        maximum: null,
        gradient: null,
        hottestLabel: null,
        availableSensors: 0,
      );
    }
    available.sort(
      (a, b) => a.measurement.value!.compareTo(b.measurement.value!),
    );
    return TemperatureDistribution(
      minimum: available.first.measurement.value,
      maximum: available.last.measurement.value,
      gradient:
          available.last.measurement.value! -
          available.first.measurement.value!,
      hottestLabel: available.last.label,
      availableSensors: available.length,
    );
  }

  ParallelDiagnosticResult analyzeParallel(List<ModuleStatus> modules) {
    if (modules.isEmpty) {
      return const ParallelDiagnosticResult(
        socSpread: null,
        currentSpread: null,
        duplicateAddresses: {},
        masterCount: 0,
        findings: [],
      );
    }
    final counts = <int, int>{};
    for (final module in modules) {
      counts[module.address] = (counts[module.address] ?? 0) + 1;
    }
    final duplicates = {
      for (final entry in counts.entries)
        if (entry.value > 1) entry.key,
    };
    final socs = modules.map((e) => e.soc).toList()..sort();
    final currents = modules.map((e) => e.current).toList()..sort();
    final masters = modules.where((e) => e.role == 'master').length;
    final findings = <DiagnosticFinding>[];
    if (duplicates.isNotEmpty) {
      findings.add(
        DiagnosticFinding(
          code: 'DUPLICATE_ADDRESS',
          severity: DiagnosticSeverity.critical,
          titleKey: 'duplicate_address',
          detailKey: 'duplicate_address_detail',
          evidence: {'addresses': duplicates.join(',')},
          confidence: DiagnosticConfidence.high,
        ),
      );
    }
    if (masters != 1) {
      findings.add(
        DiagnosticFinding(
          code: 'MASTER_ROLE',
          severity: DiagnosticSeverity.critical,
          titleKey: 'master_role',
          detailKey: 'master_role_detail',
          evidence: {'master_count': masters},
          confidence: DiagnosticConfidence.high,
        ),
      );
    }
    return ParallelDiagnosticResult(
      socSpread: socs.last - socs.first,
      currentSpread: currents.last - currents.first,
      duplicateAddresses: duplicates,
      masterCount: masters,
      findings: List.unmodifiable(findings),
    );
  }

  List<SnapshotDifference> compare(
    TelemetrySnapshot before,
    TelemetrySnapshot after,
  ) => [
    _difference('voltage', before.voltage, after.voltage),
    _difference('current', before.current, after.current),
    _difference('soc', before.soc, after.soc),
    _difference('temperature', before.temperature, after.temperature),
  ];

  HealthTrend capacityTrend(List<TelemetrySnapshot> samples) {
    final reported = samples
        .map((sample) => sample.fullChargeCapacity.value)
        .whereType<double>()
        .toList();
    if (reported.length < 2) {
      return const HealthTrend(
        capacityChange: null,
        methodNote:
            'At least two device-reported full-charge capacity samples are required.',
        uncertainty: null,
        available: false,
      );
    }
    final change = reported.last - reported.first;
    return HealthTrend(
      capacityChange: change,
      methodNote:
          'Difference of first and last device-reported full-charge capacity; not an SOH estimate.',
      uncertainty: cellStandardDeviation(samples.last),
      available: true,
    );
  }

  SnapshotDifference _difference(
    String field,
    Measurement before,
    Measurement after,
  ) {
    final available = before.value != null && after.value != null;
    return SnapshotDifference(
      field: field,
      before: before.value,
      after: after.value,
      delta: available ? after.value! - before.value! : null,
      available: available,
    );
  }
}
