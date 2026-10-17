import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/integration/compatibility_engine.dart';
import 'package:solardiag_pro/integration/compatibility_models.dart';
import 'package:solardiag_pro/integration/link_diagnostics.dart';

void main() {
  const battery = BatteryIntegrationProfile(
    chargeVoltageWindow: SourcedValue.reported(
      VoltageWindow(minimum: 52, maximum: 56.8),
      EvidenceSource.verifiedProfile,
    ),
    dischargeVoltageWindow: SourcedValue.reported(
      VoltageWindow(minimum: 44.8, maximum: 56.8),
      EvidenceSource.verifiedProfile,
    ),
    maximumChargeCurrent: SourcedValue.reported(
      100,
      EvidenceSource.verifiedProfile,
    ),
    maximumDischargeCurrent: SourcedValue.reported(
      120,
      EvidenceSource.verifiedProfile,
    ),
    chemistry: SourcedValue.reported('LiFePO4', EvidenceSource.verifiedProfile),
    spokenProtocols: {'CAN-PYLON'},
  );

  test('compatible evidence produces a compatible assessment', () {
    const inverter = InverterIntegrationProfile(
      configuredChargeVoltage: SourcedValue.reported(
        55.2,
        EvidenceSource.deviceReported,
      ),
      configuredLowVoltageCutoff: SourcedValue.reported(
        47,
        EvidenceSource.deviceReported,
      ),
      configuredChargeCurrent: SourcedValue.reported(
        80,
        EvidenceSource.deviceReported,
      ),
      configuredDischargeCurrent: SourcedValue.reported(
        100,
        EvidenceSource.deviceReported,
      ),
      supportedChemistries: {'LiFePO4'},
      supportedBatteryProtocols: {'CAN-PYLON'},
    );
    final result = const CompatibilityEngine().assess(
      battery: battery,
      inverter: inverter,
    );
    expect(result.overall, CompatibilityState.compatible);
    expect(result.findings, hasLength(6));
  });

  test('unsafe voltage and current are incompatible', () {
    const inverter = InverterIntegrationProfile(
      configuredChargeVoltage: SourcedValue.reported(
        58,
        EvidenceSource.deviceReported,
      ),
      configuredLowVoltageCutoff: SourcedValue.reported(
        43,
        EvidenceSource.deviceReported,
      ),
      configuredChargeCurrent: SourcedValue.reported(
        150,
        EvidenceSource.deviceReported,
      ),
      configuredDischargeCurrent: SourcedValue.reported(
        140,
        EvidenceSource.deviceReported,
      ),
      supportedChemistries: {'NMC'},
      supportedBatteryProtocols: {'MODBUS-UNKNOWN'},
    );
    final result = const CompatibilityEngine().assess(
      battery: battery,
      inverter: inverter,
    );
    expect(result.overall, CompatibilityState.incompatible);
    expect(
      result.findings.where(
        (item) => item.state == CompatibilityState.incompatible,
      ),
      hasLength(6),
    );
  });

  test('missing evidence remains unknown instead of compatible', () {
    const inverter = InverterIntegrationProfile(
      configuredChargeVoltage: SourcedValue.unavailable('not_reported'),
      configuredLowVoltageCutoff: SourcedValue.unavailable('not_supported'),
      configuredChargeCurrent: SourcedValue.unavailable('read_failed'),
      configuredDischargeCurrent: SourcedValue.unavailable('not_reported'),
      supportedChemistries: {},
      supportedBatteryProtocols: {},
    );
    final result = const CompatibilityEngine().assess(
      battery: battery,
      inverter: inverter,
    );
    expect(result.overall, CompatibilityState.unknown);
    expect(
      result.findings.every((item) => item.state == CompatibilityState.unknown),
      isTrue,
    );
  });

  group('link diagnostics', () {
    test('healthy observations are compatible', () {
      final result = const LinkDiagnostics().analyze(
        const LinkObservation(
          window: Duration(seconds: 10),
          expectedMessages: 100,
          receivedMessages: 99,
          timeouts: 0,
          crcFailures: 0,
          inverterSoc: SourcedValue.reported(79, EvidenceSource.deviceReported),
          batterySoc: SourcedValue.reported(78, EvidenceSource.deviceReported),
        ),
      );
      expect(result.state, CompatibilityState.compatible);
      expect(result.messageDeliveryRatio, .99);
      expect(result.socDelta, 1);
    });
    test('loss, errors, and SOC disagreement require attention', () {
      final result = const LinkDiagnostics().analyze(
        const LinkObservation(
          window: Duration(seconds: 10),
          expectedMessages: 100,
          receivedMessages: 70,
          timeouts: 3,
          crcFailures: 2,
          inverterSoc: SourcedValue.reported(55, EvidenceSource.deviceReported),
          batterySoc: SourcedValue.reported(78, EvidenceSource.deviceReported),
        ),
      );
      expect(result.state, CompatibilityState.attention);
      expect(
        result.findings.where(
          (item) => item.state == CompatibilityState.attention,
        ),
        hasLength(3),
      );
    });
    test('missing SOC values do not become zero', () {
      final result = const LinkDiagnostics().analyze(
        const LinkObservation(
          window: Duration(seconds: 10),
          expectedMessages: 0,
          receivedMessages: 0,
          timeouts: 0,
          crcFailures: 0,
          inverterSoc: SourcedValue.unavailable('not_reported'),
          batterySoc: SourcedValue.unavailable('not_reported'),
        ),
      );
      expect(result.state, CompatibilityState.unknown);
      expect(result.messageDeliveryRatio, isNull);
      expect(result.socDelta, isNull);
    });
  });
}
