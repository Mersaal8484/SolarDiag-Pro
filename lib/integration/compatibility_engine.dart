import 'compatibility_models.dart';

class CompatibilityEngine {
  const CompatibilityEngine();

  CompatibilityAssessment assess({
    required BatteryIntegrationProfile battery,
    required InverterIntegrationProfile inverter,
  }) => CompatibilityAssessment(
    List.unmodifiable([
      _withinWindow(
        code: 'CHARGE_VOLTAGE',
        configured: inverter.configuredChargeVoltage,
        window: battery.chargeVoltageWindow,
      ),
      _withinWindow(
        code: 'LOW_VOLTAGE_CUTOFF',
        configured: inverter.configuredLowVoltageCutoff,
        window: battery.dischargeVoltageWindow,
      ),
      _withinLimit(
        code: 'CHARGE_CURRENT',
        configured: inverter.configuredChargeCurrent,
        maximum: battery.maximumChargeCurrent,
      ),
      _withinLimit(
        code: 'DISCHARGE_CURRENT',
        configured: inverter.configuredDischargeCurrent,
        maximum: battery.maximumDischargeCurrent,
      ),
      _chemistry(battery, inverter),
      _protocol(battery, inverter),
    ]),
  );

  List<IntegrationRecommendation> recommendations(
    CompatibilityAssessment assessment,
  ) => [
    for (final finding in assessment.findings)
      if (finding.state == CompatibilityState.incompatible)
        IntegrationRecommendation(
          device: 'inverter',
          setting: finding.code,
          menu: 'manufacturer-documented menu required',
          suggestedValue: 'within verified battery profile',
          reason: finding.message,
        ),
  ];

  CompatibilityFinding _withinWindow({
    required String code,
    required SourcedValue<double> configured,
    required SourcedValue<VoltageWindow> window,
  }) {
    if (!configured.isAvailable || !window.isAvailable) {
      return CompatibilityFinding(
        code: code,
        state: CompatibilityState.unknown,
        evidence: {
          'configured_reason': configured.reason,
          'window_reason': window.reason,
        },
        message: 'Required voltage evidence is unavailable.',
      );
    }
    final value = configured.value!;
    final expected = window.value!;
    return CompatibilityFinding(
      code: code,
      state: expected.contains(value)
          ? CompatibilityState.compatible
          : CompatibilityState.incompatible,
      evidence: {
        'configured_v': value,
        'minimum_v': expected.minimum,
        'maximum_v': expected.maximum,
        'configured_source': configured.source.name,
        'window_source': window.source.name,
      },
      message: expected.contains(value)
          ? 'Configured voltage is inside the verified battery window.'
          : 'Configured voltage is outside the verified battery window.',
    );
  }

  CompatibilityFinding _withinLimit({
    required String code,
    required SourcedValue<double> configured,
    required SourcedValue<double> maximum,
  }) {
    if (!configured.isAvailable || !maximum.isAvailable) {
      return CompatibilityFinding(
        code: code,
        state: CompatibilityState.unknown,
        evidence: {
          'configured_reason': configured.reason,
          'maximum_reason': maximum.reason,
        },
        message: 'Required current evidence is unavailable.',
      );
    }
    final safe = configured.value! <= maximum.value!;
    return CompatibilityFinding(
      code: code,
      state: safe
          ? CompatibilityState.compatible
          : CompatibilityState.incompatible,
      evidence: {
        'configured_a': configured.value,
        'maximum_a': maximum.value,
        'configured_source': configured.source.name,
        'maximum_source': maximum.source.name,
      },
      message: safe
          ? 'Configured current does not exceed the verified battery limit.'
          : 'Configured current exceeds the verified battery limit.',
    );
  }

  CompatibilityFinding _chemistry(
    BatteryIntegrationProfile battery,
    InverterIntegrationProfile inverter,
  ) {
    if (!battery.chemistry.isAvailable ||
        inverter.supportedChemistries.isEmpty) {
      return CompatibilityFinding(
        code: 'CHEMISTRY',
        state: CompatibilityState.unknown,
        evidence: {'reason': battery.chemistry.reason},
        message: 'Chemistry compatibility cannot be proven.',
      );
    }
    final supported = inverter.supportedChemistries.contains(
      battery.chemistry.value,
    );
    return CompatibilityFinding(
      code: 'CHEMISTRY',
      state: supported
          ? CompatibilityState.compatible
          : CompatibilityState.incompatible,
      evidence: {
        'battery_chemistry': battery.chemistry.value,
        'supported': inverter.supportedChemistries.join(','),
      },
      message: supported
          ? 'Battery chemistry is supported by the inverter profile.'
          : 'Battery chemistry is not declared as supported.',
    );
  }

  CompatibilityFinding _protocol(
    BatteryIntegrationProfile battery,
    InverterIntegrationProfile inverter,
  ) {
    if (battery.spokenProtocols.isEmpty ||
        inverter.supportedBatteryProtocols.isEmpty) {
      return const CompatibilityFinding(
        code: 'PROTOCOL',
        state: CompatibilityState.unknown,
        evidence: {},
        message: 'No verified protocol intersection can be evaluated.',
      );
    }
    final intersection = battery.spokenProtocols.intersection(
      inverter.supportedBatteryProtocols,
    );
    return CompatibilityFinding(
      code: 'PROTOCOL',
      state: intersection.isNotEmpty
          ? CompatibilityState.compatible
          : CompatibilityState.incompatible,
      evidence: {
        'shared_protocols': intersection.join(','),
        'battery_protocols': battery.spokenProtocols.join(','),
        'inverter_protocols': inverter.supportedBatteryProtocols.join(','),
      },
      message: intersection.isNotEmpty
          ? 'A verified battery protocol is shared.'
          : 'No declared battery protocol is shared.',
    );
  }
}
