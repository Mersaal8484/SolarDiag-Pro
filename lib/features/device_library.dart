import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/generated/app_localizations.dart';

class DeviceLibraryScreen extends StatelessWidget {
  const DeviceLibraryScreen({super.key});
  static const freconName = 'FRECON PV100 / PV200';
  static const targets = [
    'Pylontech',
    'Dyness',
    'Felicity Solar Lithium',
    'Growatt ARK',
    'Deye Lithium',
    'JK BMS',
    'JBD / Xiaoxiang',
    'Daly',
    'Seplos',
  ];
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _Page(
      title: s.deviceLibrary,
      subtitle: s.libraryVerificationNote,
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: _Badge(text: s.simulated, color: SolarColors.lime),
            title: Text(s.deterministicBms),
            subtitle: Text(s.simulatorOnly),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.solar_power_outlined),
            title: const Text(freconName),
            subtitle: Text(s.registerMapRequired),
            trailing: _Badge(
              text: s.research,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.researchTargets,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        ...targets.map(
          (name) => Card(
            child: ListTile(
              leading: const Icon(Icons.battery_unknown_outlined),
              title: Text(name),
              subtitle: Text(s.noVerifiedDefinition),
              trailing: _Badge(
                text: s.planned,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(title, style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 8),
      Text(subtitle),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}
