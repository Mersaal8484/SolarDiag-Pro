import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../identification/identification_state_machine.dart';
import 'identification_evidence_panel.dart';

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({this.identificationOutcome, super.key});
  final IdentificationOutcome? identificationOutcome;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.pick('Diagnostic gateway', 'بوابة التشخيص'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          s.pick(
            'Connection checklist and declared capabilities.',
            'قائمة فحص الاتصال والقدرات المعلنة.',
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 24,
              runSpacing: 18,
              children: [
                _Status(
                  icon: Icons.visibility_outlined,
                  label: s.pick('Default mode', 'الوضع الافتراضي'),
                  value: s.pick('Listen-only', 'استماع فقط'),
                ),
                const _Status(
                  icon: Icons.thermostat_outlined,
                  label: 'Gateway',
                  value: 'Not connected',
                ),
                const _Status(
                  icon: Icons.security,
                  label: 'TX allow-list',
                  value: 'ENFORCED',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.pick('Connection checklist', 'قائمة فحص الاتصال'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        for (final item in [
          s.pick(
            'Use an isolated interface appropriate for the device.',
            'استخدم واجهة معزولة مناسبة للجهاز.',
          ),
          s.pick(
            'Confirm connector pinout from a verified profile.',
            'تحقق من أطراف الموصل من ملف موثق.',
          ),
          s.pick(
            'Confirm termination before enabling the bus.',
            'تحقق من المقاومة الطرفية قبل تمكين الناقل.',
          ),
          s.pick(
            'Transmission remains blocked without an active profile.',
            'يبقى الإرسال محظورًا دون ملف نشط.',
          ),
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_box_outline_blank),
              title: Text(item),
            ),
          ),
        const SizedBox(height: 18),
        if (identificationOutcome case final outcome?) ...[
          IdentificationEvidencePanel(outcome: outcome),
          const SizedBox(height: 18),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            'RS485',
            'RS232',
            'CAN 125k',
            'CAN 250k',
            'CAN 500k',
            'CAN 1M',
            'UART',
            'BLE',
          ].map((item) => Chip(label: Text(item))).toList(),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Row(
      children: [
        Icon(icon, color: SolarColors.green),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    ),
  );
}
