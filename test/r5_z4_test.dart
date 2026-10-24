import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/integration/compatibility_models.dart';
import 'package:solardiag_pro/protocol/bms_adapter.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';

import 'support/test_secret_store.dart';

BatteryIntegrationProfile _batteryProfile() => const BatteryIntegrationProfile(
  chargeVoltageWindow: SourcedValue.reported(
    VoltageWindow(minimum: 50, maximum: 56),
    EvidenceSource.verifiedProfile,
  ),
  dischargeVoltageWindow: SourcedValue.reported(
    VoltageWindow(minimum: 44, maximum: 56),
    EvidenceSource.verifiedProfile,
  ),
  maximumChargeCurrent: SourcedValue.reported(
    100,
    EvidenceSource.verifiedProfile,
  ),
  maximumDischargeCurrent: SourcedValue.reported(
    100,
    EvidenceSource.verifiedProfile,
  ),
  chemistry: SourcedValue.reported('LFP', EvidenceSource.verifiedProfile),
  spokenProtocols: {'CAN-A'},
);

InverterIntegrationProfile _inverterProfile({
  double chargeVoltage = 54,
  double chargeCurrent = 80,
  EvidenceSource chargeVoltageSource = EvidenceSource.deviceReported,
  Set<String> protocols = const {'CAN-A'},
}) => InverterIntegrationProfile(
  configuredChargeVoltage: SourcedValue.reported(
    chargeVoltage,
    chargeVoltageSource,
  ),
  configuredLowVoltageCutoff: const SourcedValue.reported(
    47,
    EvidenceSource.deviceReported,
  ),
  configuredChargeCurrent: SourcedValue.reported(
    chargeCurrent,
    EvidenceSource.deviceReported,
  ),
  configuredDischargeCurrent: const SourcedValue.reported(
    80,
    EvidenceSource.deviceReported,
  ),
  supportedChemistries: const {'LFP'},
  supportedBatteryProtocols: protocols,
);

DeviceSession _session({
  required InverterIntegrationProfile inverter,
  LinkHealth Function()? linkHealthReader,
}) => DeviceSession(
  scenario: SimulationScenario.inverterPeer,
  autoStart: false,
  auditSecretStore: TestSecretStore(),
  batteryIntegrationProfile: _batteryProfile(),
  inverterIntegrationProfile: inverter,
  linkHealthReader: linkHealthReader,
);

void main() {
  test('inverter peer compatible case flows through DeviceSession', () {
    final session = _session(inverter: _inverterProfile());
    addTearDown(session.dispose);

    expect(
      session.compatibilityAssessment.overall,
      CompatibilityState.compatible,
    );
  });

  test('inverter peer limits-restricted case flows through DeviceSession', () {
    final session = _session(
      inverter: _inverterProfile(chargeCurrent: 98),
    );
    addTearDown(session.dispose);

    expect(
      session.compatibilityAssessment.overall,
      CompatibilityState.attention,
    );
  });

  test('inverter peer incompatible-protocol case flows through DeviceSession', () {
    final session = _session(
      inverter: _inverterProfile(protocols: const {'OTHER'}),
    );
    addTearDown(session.dispose);

    expect(
      session.compatibilityAssessment.overall,
      CompatibilityState.incompatible,
    );
  });

  test('user-provided compatibility evidence is capped at attention', () {
    final session = _session(
      inverter: _inverterProfile(
        chargeVoltageSource: EvidenceSource.userProvided,
      ),
    );
    addTearDown(session.dispose);

    final finding = session.compatibilityAssessment.findings.singleWhere(
      (item) => item.code == 'CHARGE_VOLTAGE',
    );
    expect(finding.state, CompatibilityState.attention); 
    expect(finding.evidenceQuality, EvidenceQuality.userProvided);
  });

  test('compatibility near-limit margin is reported through DeviceSession', () {
    final session = _session(
      inverter: _inverterProfile(chargeVoltage: 50.2),
    );
    addTearDown(session.dispose);

    final finding = session.compatibilityAssessment.findings.singleWhere(
      (item) => item.code == 'CHARGE_VOLTAGE',
    );
    expect(finding.evidence['near_limit'], isTrue);
    expect(finding.state, CompatibilityState.attention);
  });

  test('link diagnostics use scripted transport counters', () async {
    final session = _session(
      inverter: _inverterProfile(),
      linkHealthReader: () => const LinkHealth(
        latency: Duration(milliseconds: 20),
        errorRate: .25,
        timeouts: 1,
        crcFailures: 2,
      ),
    );
    addTearDown(session.dispose);

    await session.refresh();

    expect(session.linkDiagnostics.messageDeliveryRatio, .75);
    expect(session.linkDiagnostics.state, CompatibilityState.attention);
    expect(
      session.linkDiagnostics.findings.any(
        (finding) => finding.code == 'LINK_ERRORS',
      ),
      isTrue,
    );
  });

  test('link diagnostics are unknown before counters are available', () {
    final session = _session(inverter: _inverterProfile());
    addTearDown(session.dispose);

    expect(session.linkDiagnostics.messageDeliveryRatio, isNull);
    expect(session.linkDiagnostics.state, CompatibilityState.unknown);
  });
}
