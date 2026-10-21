import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme.dart';
import '../integration/compatibility_models.dart';
import '../session/device_session.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final assessment = session.compatibilityAssessment;
    final link = session.linkDiagnostics;
    final recommendations = session.integrationRecommendations;
    final delivery = link.messageDeliveryRatio;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.inverterBatteryLink,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(s.linkDescription),
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
                      [
                        session.simulated ? s.simulated : s.live,
                        _verdictLabel(s, assessment.verdict),
                      ].join(' · '),
                      style: const TextStyle(
                        color: SolarColors.onDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      delivery == null
                          ? s.deliveryUnavailable
                          : '${(delivery * 100).toStringAsFixed(0)}% ${s.messageDelivery}',
                      style: const TextStyle(color: SolarColors.onDarkStrong),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          assessment.verdict == IntegrationVerdict.cannotDetermine
              ? s.requiredEvidenceUnavailable
              : assessment.explanation,
        ),
        const SizedBox(height: 18),
        ...assessment.findings.map((finding) => _FindingTile(finding: finding)),
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final item in recommendations)
            Card(
              child: ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: Text([item.device, item.setting].join(': ')),
                subtitle: Text(
                  [item.suggestedValue, item.menu, item.reason].join(' · '),
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        Text(
          s.recommendationsNeverApplied,
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
    final s = AppLocalizations.of(context);
    final ok = finding.state == CompatibilityState.compatible;
    return Card(
      child: ListTile(
        leading: Icon(
          ok ? Icons.check_circle : Icons.help_outline,
          color: ok
              ? Theme.of(context).extension<SolarTokens>()!.success
              : Theme.of(context).extension<SolarTokens>()!.warning,
        ),
        title: Text(_findingTitle(s, finding.code)),
        subtitle: Text(_findingMessage(s, finding)),
        trailing: Text(
          finding.state == CompatibilityState.unknown
              ? s.unknown.toUpperCase()
              : finding.state.name.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _verdictLabel(AppLocalizations s, IntegrationVerdict verdict) =>
    verdict == IntegrationVerdict.cannotDetermine
    ? s.compatibilityCannotDetermine
    : verdict.name;

String _findingTitle(AppLocalizations s, String code) => switch (code) {
  'CHARGE_VOLTAGE' => s.chargeVoltage,
  'LOW_VOLTAGE_CUTOFF' => s.lowVoltageCutoff,
  'CHARGE_CURRENT' => s.chargeCurrent,
  'DISCHARGE_CURRENT' => s.dischargeCurrent,
  'CHEMISTRY' => s.chemistry,
  'PROTOCOL' => s.protocol,
  _ => code.replaceAll('_', ' '),
};

String _findingMessage(AppLocalizations s, CompatibilityFinding finding) =>
    switch (finding.code) {
      'CHARGE_VOLTAGE' || 'LOW_VOLTAGE_CUTOFF'
          when finding.state == CompatibilityState.unknown =>
        s.requiredVoltageEvidenceUnavailable,
      'CHARGE_CURRENT' || 'DISCHARGE_CURRENT'
          when finding.state == CompatibilityState.unknown =>
        s.requiredCurrentEvidenceUnavailable,
      'CHEMISTRY' when finding.state == CompatibilityState.unknown =>
        s.chemistryCompatibilityUnproven,
      'PROTOCOL' when finding.state == CompatibilityState.unknown =>
        s.protocolIntersectionUnavailable,
      _ => finding.message,
    };
