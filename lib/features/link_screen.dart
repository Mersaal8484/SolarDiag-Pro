import 'package:flutter/material.dart';
import '../design/precision_ui.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../design/accessibility.dart';
import '../integration/compatibility_models.dart';
import '../session/device_session.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final session = DeviceSessionScope.of(context);
    final assessment = session.compatibilityAssessment;
    final link = session.linkDiagnostics;
    final recommendations = session.integrationRecommendations;
    final delivery = link.messageDeliveryRatio;
    final deliveryLabel = delivery == null
        ? s.deliveryUnavailable
        : localizedMeasurement(context, delivery * 100, '%');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 64),
      children: [
        PrecisionPageHeading(
          title: s.inverterBatteryLink,
          subtitle: s.linkDescription,
          icon: SolarIcons.linkDiagnostics,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.surfaceRaised, palette.surface],
            ),
            border: Border.all(color: palette.separator),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              SolarIcon(
                SolarIcons.linkDiagnostics,
                color: palette.simulated,
                size: 30,
              ),
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
                      style: TextStyle(
                        color: palette.labelPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Semantics(
                      label:
                          '${s.messageDelivery}, $deliveryLabel, ${s.updatedNow}',
                      child: ExcludeSemantics(
                        child: Text(
                          delivery == null
                              ? deliveryLabel
                              : '$deliveryLabel ${s.messageDelivery}',
                          style: TextStyle(color: palette.labelSecondary),
                        ),
                      ),
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
            PrecisionCard(
              child: ListTile(
                leading: const SolarIcon(SolarIcons.evidence),
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
    return PrecisionCard(
      child: ListTile(
        leading: SolarIcon(
          ok ? SolarIcons.confirmedCheck : SolarIcons.warning,
          color: ok
              ? Theme.of(context).extension<SolarTokens>()!.success
              : Theme.of(context).extension<SolarTokens>()!.warning,
        ),
        title: Text(_findingTitle(s, finding.code)),
        subtitle: Text(_findingMessage(s, finding)),
        trailing: Text(
          _compatibilityStateLabel(s, finding.state).toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _verdictLabel(AppLocalizations s, IntegrationVerdict verdict) =>
    switch (verdict) {
      IntegrationVerdict.compatible => s.compatibilityCompatible,
      IntegrationVerdict.compatibleWithLimits =>
        s.compatibilityCompatibleWithLimits,
      IntegrationVerdict.incompatibleProfile => s.compatibilityIncompatible,
      IntegrationVerdict.cannotDetermine => s.compatibilityCannotDetermine,
    };

String _compatibilityStateLabel(AppLocalizations s, CompatibilityState state) =>
    switch (state) {
      CompatibilityState.compatible => s.compatibilityStateCompatible,
      CompatibilityState.attention => s.compatibilityStateAttention,
      CompatibilityState.incompatible => s.compatibilityStateIncompatible,
      CompatibilityState.unknown => s.unknown,
    };

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
