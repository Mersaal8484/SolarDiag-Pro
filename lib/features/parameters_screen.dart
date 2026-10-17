import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme.dart';

class ParametersScreen extends StatelessWidget {
  const ParametersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(s.parameters, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(s.simulatorValuesNotice),
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
                  s.simulatedWritePipeline,
                  style: const TextStyle(
                    color: SolarColors.onDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ParameterTile(
          title: s.chargeVoltageLimit,
          value: '55.2 V',
          range: '50.0â€“56.0 V Â· 0.1 V',
        ),
        _ParameterTile(
          title: s.chargeCurrentLimit,
          value: '80 A',
          range: '0â€“100 A Â· 1 A',
        ),
        _ParameterTile(
          title: s.lowVoltageCutoff,
          value: '47.0 V',
          range: '44.8â€“52.0 V Â· 0.1 V',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.backup_outlined),
              label: Text(s.createBackup),
            ),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.edit_off_outlined),
              label: Text(s.physicalWriteLocked),
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
