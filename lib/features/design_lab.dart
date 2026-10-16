import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';

class DesignLab extends StatelessWidget {
  const DesignLab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final tokens = Theme.of(context).extension<SolarTokens>()!;
    return Scaffold(
      appBar: AppBar(title: Text(s.designLab)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            s.pick('Interface foundations', 'أسس الواجهة'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            s.pick(
              'A living reference for tokens, states, type and controls.',
              'مرجع حي للألوان والحالات والخطوط وعناصر التحكم.',
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Swatch(label: s.pick('Success', 'سليم'), color: tokens.success),
              _Swatch(label: s.pick('Warning', 'تحذير'), color: tokens.warning),
              _Swatch(label: s.simulated, color: tokens.simulated),
              _Swatch(label: s.pick('Panel', 'لوحة'), color: tokens.panel),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.pick('Measurement states', 'حالات القياس'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '51.24 V',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    s.missing,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () {},
                        child: Text(s.pick('Primary action', 'إجراء رئيسي')),
                      ),
                      OutlinedButton(
                        onPressed: null,
                        child: Text(
                          s.pick('Unavailable safely', 'غير متاح بأمان'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    height: 92,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    alignment: AlignmentDirectional.bottomStart,
    child: Text(
      label,
      style: const TextStyle(
        color: SolarColors.ink,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
