enum CompatibilityState { compatible, attention, incompatible, unknown }

enum EvidenceSource {
  deviceReported,
  verifiedProfile,
  userProvided,
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
  });
  final String code;
  final CompatibilityState state;
  final Map<String, Object?> evidence;
  final String message;
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
}
