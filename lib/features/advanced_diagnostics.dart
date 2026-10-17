import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../core/battery_models.dart';
import '../diagnostics/battery_diagnostics.dart';
import '../diagnostics/diagnostic_models.dart';

class AdvancedDiagnosticsScreen extends StatelessWidget {
  const AdvancedDiagnosticsScreen({
    super.key,
    required this.snapshot,
    this.alarmCodes = const {},
  });
  final BatterySnapshot snapshot;
  final Set<String> alarmCodes;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final assessment = const BatteryDiagnostics().analyze(
      snapshot,
      rawAlarmCodes: alarmCodes,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(s.pick('Advanced diagnostics', 'التشخيص المتقدم')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            s.pick('Evidence before conclusions.', 'الدليل قبل الاستنتاج.'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(
            s.pick(
              'Every finding below is tied to a reported value or raw alarm. Missing evidence stays unavailable.',
              'كل نتيجة أدناه مرتبطة بقيمة مبلّغ عنها أو إنذار خام. عند غياب الدليل تبقى النتيجة غير متاحة.',
            ),
          ),
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
    final s = AppStrings.of(context);
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
                  s.pick(
                    'State of health: not available',
                    'حالة الصحة: غير متاحة',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.pick(
                    'The device did not report SOH and available samples cannot prove it.',
                    'لم يبلغ الجهاز عن SOH ولا تكفي العينات المتاحة لإثباتها.',
                  ),
                  style: const TextStyle(color: Colors.white70),
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
    final s = AppStrings.of(context);
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
                              label: Text(
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
  static String _title(AppStrings s, String key) => switch (key) {
    'cells_balanced' => s.pick('Cells are balanced', 'الخلايا متوازنة'),
    'cell_imbalance' => s.pick(
      'Cell imbalance detected',
      'تم اكتشاف اختلال بالخلايا',
    ),
    'temperature_unavailable' => s.pick(
      'Temperature unavailable',
      'درجة الحرارة غير متاحة',
    ),
    'temperature_normal' => s.pick(
      'Temperature is normal',
      'درجة الحرارة طبيعية',
    ),
    'temperature_high' => s.pick('High temperature', 'درجة حرارة مرتفعة'),
    'cell_overvoltage' => s.pick(
      'Cell overvoltage alarm',
      'إنذار ارتفاع جهد خلية',
    ),
    _ => s.pick('Unrecognized device alarm', 'إنذار جهاز غير معروف'),
  };
  static String _detail(AppStrings s, String key) => switch (key) {
    'cells_balanced_detail' => s.pick(
      'The reported cell spread is within the configured attention threshold.',
      'فرق الخلايا المبلّغ عنه ضمن حد الانتباه المحدد.',
    ),
    'cell_imbalance_detail' => s.pick(
      'The reported spread exceeds the configured threshold. Inspect raw cell values.',
      'الفرق المبلّغ عنه يتجاوز الحد المحدد. راجع قيم الخلايا الخام.',
    ),
    'temperature_unavailable_detail' => s.pick(
      'No temperature value was reported; no thermal conclusion was made.',
      'لم تُبلغ قيمة للحرارة؛ لذلك لم يصدر استنتاج حراري.',
    ),
    'temperature_normal_detail' => s.pick(
      'The reported temperature is below the configured warning threshold.',
      'درجة الحرارة المبلّغ عنها أدنى من حد التحذير المحدد.',
    ),
    'temperature_high_detail' => s.pick(
      'The reported temperature exceeds a configured safety threshold.',
      'درجة الحرارة المبلّغ عنها تتجاوز حد أمان محدد.',
    ),
    'cell_overvoltage_detail' => s.pick(
      'The BMS raw alarm map reports cell overvoltage.',
      'خريطة إنذارات BMS الخام تبلغ عن ارتفاع جهد خلية.',
    ),
    _ => s.pick(
      'The raw code is preserved without guessing its meaning.',
      'تم الاحتفاظ بالرمز الخام دون تخمين معناه.',
    ),
  };
}
