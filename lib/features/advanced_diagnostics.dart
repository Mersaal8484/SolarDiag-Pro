import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme.dart';
import '../design/accessibility.dart';
import '../diagnostics/battery_diagnostics.dart';
import '../diagnostics/diagnostic_models.dart';
import '../session/device_session.dart';

class AdvancedDiagnosticsScreen extends StatelessWidget {
  const AdvancedDiagnosticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final assessment = const BatteryDiagnostics().analyze(
      session.snapshot,
      rawAlarmCodes: session.alarmCodes,
    );
    return Scaffold(
      appBar: AppBar(title: Text(s.advancedDiagnostics)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            s.evidenceBeforeConclusions,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(s.diagnosticEvidenceNote),
          const SizedBox(height: 24),
          _SohUnavailable(reason: assessment.reason),
          const SizedBox(height: 16),
          for (final finding in assessment.findings)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FindingCard(finding: finding),
            ),
        ],
      ),
    );
  }
}

class _SohUnavailable extends StatelessWidget {
  const _SohUnavailable({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SolarColors.deep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: SolarColors.lime),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.sohUnavailable,
                  style: const TextStyle(
                    color: SolarColors.onDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.sohUnavailableReason,
                  style: const TextStyle(color: SolarColors.onDarkStrong),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});
  final DiagnosticFinding finding;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<SolarTokens>()!;
    final color = switch (finding.severity) {
      DiagnosticSeverity.info => tokens.success,
      DiagnosticSeverity.attention => tokens.warning,
      DiagnosticSeverity.warning => tokens.warning,
      DiagnosticSeverity.critical => Theme.of(context).colorScheme.error,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title(s, finding.titleKey),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(
                        finding.confidence.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_detail(s, finding.detailKey)),
                  if (finding.evidence.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: finding.evidence.entries
                          .map(
                            (entry) => Chip(
                              label: TechnicalText(
                                '${entry.key}: ${_format(entry.value)}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(Object value) =>
      value is double ? value.toStringAsFixed(3) : '$value';
  static String _title(AppLocalizations s, String key) => switch (key) {
    'cells_balanced' => s.cellsBalanced,
    'cell_imbalance' => s.cellImbalanceDetected,
    'temperature_unavailable' => s.temperatureUnavailable,
    'temperature_normal' => s.temperatureNormal,
    'temperature_high' => s.temperatureHigh,
    'cell_overvoltage' => s.cellOvervoltageAlarm,
    _ => s.unrecognizedAlarm,
  };
  static String _detail(AppLocalizations s, String key) => switch (key) {
    'cells_balanced_detail' => s.cellsBalancedDetail,
    'cell_imbalance_detail' => s.cellImbalanceDetail,
    'temperature_unavailable_detail' => s.temperatureUnavailableDetail,
    'temperature_normal_detail' => s.temperatureNormalDetail,
    'temperature_high_detail' => s.temperatureHighDetail,
    'cell_overvoltage_detail' => s.cellOvervoltageDetail,
    _ => s.rawCodePreserved,
  };
}
