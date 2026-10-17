import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';

class ParametersScreen extends StatelessWidget {
  const ParametersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.pick('Parameters', 'المعلمات'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          s.pick(
            'Simulator values. Physical writes remain unavailable.',
            'قيم المحاكي. الكتابة على الأجهزة الحقيقية غير متاحة.',
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SolarColors.deep,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(Icons.science_outlined, color: SolarColors.lime),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.pick(
                    'SIMULATED WRITE PIPELINE · Readback required',
                    'خط كتابة محاكى · القراءة الراجعة إلزامية',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ParameterTile(
          title: s.pick('Charge voltage limit', 'حد جهد الشحن'),
          value: '55.2 V',
          range: '50.0–56.0 V · 0.1 V',
        ),
        _ParameterTile(
          title: s.pick('Charge current limit', 'حد تيار الشحن'),
          value: '80 A',
          range: '0–100 A · 1 A',
        ),
        _ParameterTile(
          title: s.pick('Low-voltage cutoff', 'فصل الجهد المنخفض'),
          value: '47.0 V',
          range: '44.8–52.0 V · 0.1 V',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.backup_outlined),
              label: Text(s.pick('Create backup', 'إنشاء نسخة احتياطية')),
            ),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.edit_off_outlined),
              label: Text(
                s.pick('Physical write locked', 'الكتابة الحقيقية مقفلة'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParameterTile extends StatelessWidget {
  const _ParameterTile({
    required this.title,
    required this.value,
    required this.range,
  });
  final String title;
  final String value;
  final String range;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(20),
      title: Text(title),
      subtitle: Text(range),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
