import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../design/components.dart';

import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../l10n/generated/app_localizations.dart';
import '../trust/signed_tokens.dart';

class DeviceLibraryScreen extends StatelessWidget {
  const DeviceLibraryScreen({super.key, this.installedLibrary});
  final InstalledLibrary? installedLibrary;
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
        if (installedLibrary?.showRevokedBanner ?? false)
          RevokedBanner(
            title: s.warning,
            message: s.physicalWriteLocked,
          ),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: _Badge(
              text: s.simulated,
              color: Theme.of(
                context,
              ).extension<SolarTokens>()!.palette.simulated,
            ),
            title: Text(s.deterministicBms),
            subtitle: Text(s.simulatorOnly),
            trailing: const SolarIcon(SolarIcons.currentFlow),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const SolarIcon(SolarIcons.inverter),
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
              leading: const SolarIcon(SolarIcons.battery),
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
