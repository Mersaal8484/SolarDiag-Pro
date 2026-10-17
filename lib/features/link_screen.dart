import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../integration/compatibility_engine.dart';
import '../integration/compatibility_models.dart';
import '../integration/link_diagnostics.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final assessment = const CompatibilityEngine().assess(
      battery: _battery,
      inverter: _inverter,
    );
    final link = const LinkDiagnostics().analyze(_observation);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.pick('Inverter ↔ Battery', 'الإنفرتر ↔ البطارية'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          s.pick(
            'Read-only compatibility and communication evidence.',
            'أدلة توافق واتصال للقراءة فقط.',
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: SolarColors.deep,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, color: SolarColors.lime, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.pick('Simulated link · Healthy', 'رابط محاكى · سليم'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${(link.messageDeliveryRatio! * 100).toStringAsFixed(0)}% ${s.pick('message delivery', 'تسليم الرسائل')}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...assessment.findings.map((finding) => _FindingTile(finding: finding)),
        const SizedBox(height: 12),
        Text(
          s.pick(
            'No automatic reconfiguration is available.',
            'لا تتوفر إعادة تهيئة تلقائية.',
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.finding});
  final CompatibilityFinding finding;
  @override
  Widget build(BuildContext context) {
    final ok = finding.state == CompatibilityState.compatible;
    return Card(
      child: ListTile(
        leading: Icon(
          ok ? Icons.check_circle : Icons.help_outline,
          color: ok
              ? Theme.of(context).extension<SolarTokens>()!.success
              : Theme.of(context).extension<SolarTokens>()!.warning,
        ),
        title: Text(finding.code.replaceAll('_', ' ')),
        subtitle: Text(finding.message),
        trailing: Text(
          finding.state.name.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

const _battery = BatteryIntegrationProfile(
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
  spokenProtocols: {'CAN-SIM'},
);
const _inverter = InverterIntegrationProfile(
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
  supportedBatteryProtocols: {'CAN-SIM'},
);
const _observation = LinkObservation(
  window: Duration(seconds: 10),
  expectedMessages: 100,
  receivedMessages: 99,
  timeouts: 0,
  crcFailures: 0,
  inverterSoc: SourcedValue.reported(79, EvidenceSource.deviceReported),
  batterySoc: SourcedValue.reported(78, EvidenceSource.deviceReported),
);
