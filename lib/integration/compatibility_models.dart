enum CompatibilityState { compatible, attention, incompatible, unknown }

enum IntegrationVerdict {
  compatible,
  compatibleWithLimits,
  incompatibleProfile,
  cannotDetermine,
}

enum EvidenceSource {
  deviceReported,
  verifiedProfile,
  communitySourced, // C4: community-sourced data; downgrades compatible→attention
  userProvided,
  unavailable,
}

/// Summarises the trust level of the weakest evidence source in a finding.
/// Used by [CompatibilityEngine] to apply evidence-quality weighting (C4).
enum EvidenceQuality {
  /// Both configured value and reference came from verified sources.
  verified,

  /// At least one value came from community-sourced data; reduced confidence.
  communitySourced,

  /// At least one value was entered by a user and is not independently
  /// verified; a compatible result is capped at attention.
  userProvided,

  /// At least one value is unavailable; no quality assertion possible.
  unavailable,
}

class SourcedValue<T> {
  const SourcedValue.reported(this.value, this.source) : reason = null;
  const SourcedValue.unavailable(this.reason)
    : value = null,
      source = EvidenceSource.unavailable;
  final T? value;
  final EvidenceSource source;
  final String? reason;
  bool get isAvailable => value != null;
}

class VoltageWindow {
  const VoltageWindow({required this.minimum, required this.maximum});
  final double minimum;
  final double maximum;
  bool contains(double value) => value >= minimum && value <= maximum;
  bool containsWindow(VoltageWindow other) =>
      other.minimum >= minimum && other.maximum <= maximum;
}

class BatteryIntegrationProfile {
  const BatteryIntegrationProfile({
    required this.chargeVoltageWindow,
    required this.dischargeVoltageWindow,
    required this.maximumChargeCurrent,
    required this.maximumDischargeCurrent,
    required this.chemistry,
    required this.spokenProtocols,
  });
  final SourcedValue<VoltageWindow> chargeVoltageWindow;
  final SourcedValue<VoltageWindow> dischargeVoltageWindow;
  final SourcedValue<double> maximumChargeCurrent;
  final SourcedValue<double> maximumDischargeCurrent;
  final SourcedValue<String> chemistry;
  final Set<String> spokenProtocols;
}

class InverterIntegrationProfile {
  const InverterIntegrationProfile({
    required this.configuredChargeVoltage,
    required this.configuredLowVoltageCutoff,
    required this.configuredChargeCurrent,
    required this.configuredDischargeCurrent,
    required this.supportedChemistries,
    required this.supportedBatteryProtocols,
  });
  final SourcedValue<double> configuredChargeVoltage;
  final SourcedValue<double> configuredLowVoltageCutoff;
  final SourcedValue<double> configuredChargeCurrent;
  final SourcedValue<double> configuredDischargeCurrent;
  final Set<String> supportedChemistries;
  final Set<String> supportedBatteryProtocols;
}

class CompatibilityFinding {
  const CompatibilityFinding({
    required this.code,
    required this.state,
    required this.evidence,
    required this.message,
    this.evidenceQuality = EvidenceQuality.verified,
  });
  final String code;
  final CompatibilityState state;
  final Map<String, Object?> evidence;
  final String message;

  /// Quality of the weakest evidence source that produced this finding (C4).
  final EvidenceQuality evidenceQuality;
}

class CompatibilityAssessment {
  const CompatibilityAssessment(this.findings);
  final List<CompatibilityFinding> findings;
  CompatibilityState get overall {
    if (findings.any((item) => item.state == CompatibilityState.incompatible)) {
      return CompatibilityState.incompatible;
    }
    if (findings.any((item) => item.state == CompatibilityState.unknown)) {
      return CompatibilityState.unknown;
    }
    if (findings.any((item) => item.state == CompatibilityState.attention)) {
      return CompatibilityState.attention;
    }
    return CompatibilityState.compatible;
  }

  IntegrationVerdict get verdict => switch (overall) {
    CompatibilityState.compatible => IntegrationVerdict.compatible,
    CompatibilityState.attention => IntegrationVerdict.compatibleWithLimits,
    CompatibilityState.incompatible => IntegrationVerdict.incompatibleProfile,
    CompatibilityState.unknown => IntegrationVerdict.cannotDetermine,
  };
  String get explanation => switch (verdict) {
    IntegrationVerdict.compatible =>
      'All available verified evidence is compatible.',
    IntegrationVerdict.compatibleWithLimits =>
      'The profiles can operate together only within the listed limits.',
    IntegrationVerdict.incompatibleProfile =>
      'At least one available profile constraint is incompatible.',
    IntegrationVerdict.cannotDetermine =>
      'Required evidence is unavailable; compatibility cannot be claimed.',
  };
}

class IntegrationRecommendation {
  const IntegrationRecommendation({
    required this.device,
    required this.setting,
    required this.menu,
    required this.suggestedValue,
    required this.reason,
  });
  final String device;
  final String setting;
  final String menu;
  final String suggestedValue;
  final String reason;
}
