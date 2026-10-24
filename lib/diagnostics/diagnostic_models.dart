enum DiagnosticSeverity { info, attention, warning, critical }

enum DiagnosticConfidence { unavailable, low, medium, high }

enum DiagnosticEvidenceSource { deviceReported, unavailable }

class DiagnosticFinding {
  const DiagnosticFinding({
    required this.code,
    required this.severity,
    required this.titleKey,
    required this.detailKey,
    required this.evidence,
    required this.confidence,
  });
  final String code;
  final DiagnosticSeverity severity;
  final String titleKey;
  final String detailKey;
  final Map<String, Object> evidence;
  final DiagnosticConfidence confidence;
}

class HealthAssessment {
  const HealthAssessment({
    required this.stateOfHealth,
    required this.source,
    required this.reason,
    required this.findings,
  });
  final Measurement stateOfHealth;
  final DiagnosticEvidenceSource source;
  final DataAbsenceReason? reason;
  final List<DiagnosticFinding> findings;
}

class FaultDefinition {
  const FaultDefinition({
    required this.code,
    required this.severity,
    required this.titleKey,
    required this.detailKey,
    required this.suggestedChecksEn,
    required this.suggestedChecksAr,
  });
  final String code;
  final DiagnosticSeverity severity;
  final String titleKey;
  final String detailKey;
  final List<String> suggestedChecksEn;
  final List<String> suggestedChecksAr;
}

class SnapshotDifference {
  const SnapshotDifference({
    required this.field,
    required this.before,
    required this.after,
    required this.delta,
    required this.available,
  });
  final String field;
  final double? before;
  final double? after;
  final double? delta;
  final bool available;
}

class TemperatureDistribution {
  const TemperatureDistribution({
    required this.minimum,
    required this.maximum,
    required this.gradient,
    required this.hottestLabel,
    required this.availableSensors,
  });
  final double? minimum;
  final double? maximum;
  final double? gradient;
  final String? hottestLabel;
  final int availableSensors;
}

class ParallelDiagnosticResult {
  const ParallelDiagnosticResult({
    required this.socSpread,
    required this.currentSpread,
    required this.duplicateAddresses,
    required this.masterCount,
    required this.findings,
  });
  final double? socSpread;
  final double? currentSpread;
  final Set<int> duplicateAddresses;
  final int masterCount;
  final List<DiagnosticFinding> findings;
}

class HealthTrend {
  const HealthTrend({
    required this.capacityChange,
    required this.methodNote,
    required this.uncertainty,
    required this.available,
  });
  final double? capacityChange;
  final String methodNote;
  final double? uncertainty;
  final bool available;
}
