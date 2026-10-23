import 'compatibility_models.dart';

class CompatibilityEngine {
  const CompatibilityEngine({this.limitAttentionMargin = .05});

  final double limitAttentionMargin;

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
    final quality = _qualityOf([configured.source, window.source]);
    final compatible = expected.contains(value);
    final span = expected.maximum - expected.minimum;
    final nearLimit =
        compatible &&
        span > 0 &&
        ((value - expected.minimum).abs() / span <= limitAttentionMargin ||
            (expected.maximum - value).abs() / span <= limitAttentionMargin);
    return CompatibilityFinding(
      code: code,
      state: _weightedState(
        compatible: compatible,
        quality: quality,
        nearLimit: nearLimit,
      ),
      evidence: {
        'configured_v': value,
        'minimum_v': expected.minimum,
        'maximum_v': expected.maximum,
        'configured_source': configured.source.name,
        'window_source': window.source.name,
        'near_limit': nearLimit,
      },
      message: compatible
          ? _compatibleMessage(
              quality,
              normal: 'Configured voltage is inside the battery window.',
              nearLimit: nearLimit,
            )
          : 'Configured voltage is outside the verified battery window.',
      evidenceQuality: quality,
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
    final quality = _qualityOf([configured.source, maximum.source]);
    final nearLimit =
        safe &&
        maximum.value! > 0 &&
        configured.value! / maximum.value! >= 1 - limitAttentionMargin;
    return CompatibilityFinding(
      code: code,
      state: _weightedState(
        compatible: safe,
        quality: quality,
        nearLimit: nearLimit,
      ),
      evidence: {
        'configured_a': configured.value,
        'maximum_a': maximum.value,
        'configured_source': configured.source.name,
        'maximum_source': maximum.source.name,
        'near_limit': nearLimit,
      },
      message: safe
          ? _compatibleMessage(
              quality,
              normal: 'Configured current does not exceed the battery limit.',
              nearLimit: nearLimit,
            )
          : 'Configured current exceeds the verified battery limit.',
      evidenceQuality: quality,
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

  EvidenceQuality _qualityOf(Iterable<EvidenceSource> sources) {
    if (sources.contains(EvidenceSource.unavailable)) {
      return EvidenceQuality.unavailable;
    }
    if (sources.contains(EvidenceSource.userProvided)) {
      return EvidenceQuality.userProvided;
    }
    if (sources.contains(EvidenceSource.communitySourced)) {
      return EvidenceQuality.communitySourced;
    }
    return EvidenceQuality.verified;
  }

  CompatibilityState _weightedState({
    required bool compatible,
    required EvidenceQuality quality,
    required bool nearLimit,
  }) {
    if (!compatible) return CompatibilityState.incompatible;
    if (quality != EvidenceQuality.verified || nearLimit) {
      return CompatibilityState.attention;
    }
    return CompatibilityState.compatible;
  }

  String _compatibleMessage(
    EvidenceQuality quality, {
    required String normal,
    required bool nearLimit,
  }) {
    if (nearLimit) return '$normal The configured value is near a limit.';
    return switch (quality) {
      EvidenceQuality.communitySourced =>
        '$normal Community-sourced evidence requires verification.',
      EvidenceQuality.userProvided =>
        '$normal User-provided evidence requires verification.',
      EvidenceQuality.unavailable => 'Required evidence is unavailable.',
      EvidenceQuality.verified => normal,
    };
  }
}
