enum DiagnosticSeverity { info, attention, warning, critical }

enum DiagnosticConfidence { unavailable, low, medium, high }

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
    required this.reason,
    required this.findings,
  });
  final double? stateOfHealth;
  final String reason;
  final List<DiagnosticFinding> findings;
}
