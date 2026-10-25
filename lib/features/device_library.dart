import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../app/theme.dart';
import '../design/components.dart';

import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../l10n/generated/app_localizations.dart';
import '../protocol/research_target_registry.dart';
import '../trust/library_write_reason.dart';
import 'library_write_reason_label.dart';

class DeviceLibraryScreen extends StatelessWidget {
  const DeviceLibraryScreen({super.key, this.writeDisabledReason});
  final LibraryWriteDisabledReason? writeDisabledReason;
  static const freconName = 'FRECON PV100 / PV200';
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _Page(
      title: s.deviceLibrary,
      subtitle: s.libraryVerificationNote,
      children: [
        if (writeDisabledReason case final reason?)
          RevokedBanner(
            title: s.warning,
            message: localizedLibraryWriteReason(context, reason),
          ),
        PrecisionCard(
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
        PrecisionCard(
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
        PrecisionSectionHeading(
          label: s.researchTargets,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 10),
        ...researchTargets.map(
          (target) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: PrecisionCard(
              child: ListTile(
                leading: SolarIcon(
                  target.category == ResearchTargetCategory.battery
                      ? SolarIcons.battery
                      : SolarIcons.inverter,
                ),
                title: Text(target.manufacturer),
                subtitle: Text(s.noVerifiedDefinition),
                trailing: _Badge(
                  text: s.planned,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
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
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 64),
    children: [
      PrecisionPageHeading(
        title: title,
        subtitle: subtitle,
        icon: Icons.inventory_2_outlined,
      ),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}
