import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../design/components.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../design/tokens.g.dart';
import '../l10n/generated/app_localizations.dart';

class DesignLab extends StatelessWidget {
  const DesignLab({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cells = List<double>.generate(16, (index) => 3.18 + index * .004);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.designLab)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth > 1248
              ? (constraints.maxWidth - 1200) / 2
              : SolarSpace.xxl;
          return ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontal,
              SolarSpace.lg,
              horizontal,
              SolarSpace.hero,
            ),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SolarSpace.readableWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.designLab,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: SolarSpace.sm),
                    Text(
                      l10n.designLabIntro,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SolarSpace.section),
              _Section(title: l10n.foundations, child: const _PaletteStrip()),
              _Section(
                title: l10n.measurements,
                child: Wrap(
                  spacing: SolarSpace.md,
                  runSpacing: SolarSpace.md,
                  children: [
                    SizedBox(
                      width: 280,
                      child: MetricTile(
                        label: l10n.packVoltage,
                        value: '51.24',
                        unit: 'V',
                        updatedLabel: l10n.updatedNow,
                        simulated: true,
                      ),
                    ),
                    RingGauge(value: .78, label: l10n.stateOfCharge),
                    StatusPill(label: l10n.connected, status: SolarStatus.ok),
                    ModeBadge(label: l10n.monitor, status: SolarStatus.info),
                  ],
                ),
              ),
              _Section(
                title: l10n.cells,
                child: Column(
                  children: [
                    CellGrid(values: cells),
                    const SizedBox(height: SolarSpace.xxl),
                    CellBarChart(values: cells),
                    const SizedBox(height: SolarSpace.xxl),
                    CellHeatmap(values: cells),
                  ],
                ),
              ),
              _Section(
                title: l10n.safetyStates,
                child: Column(
                  children: [
                    SafetyBanner(
                      title: l10n.warning,
                      message: l10n.registerMapRequired,
                      status: SolarStatus.warning,
                    ),
                    const SizedBox(height: SolarSpace.md),
                    AlarmCard(
                      title: l10n.noActiveAlarms,
                      message: l10n.updatedNow,
                      status: SolarStatus.ok,
                    ),
                    const SizedBox(height: SolarSpace.md),
                    EmptyState(
                      title: l10n.emptyTitle,
                      message: l10n.emptyMessage,
                    ),
                  ],
                ),
              ),
              _Section(
                title: l10n.studioComponents,
                child: Column(
                  children: [
                    StatusPill(
                      label: l10n.passiveNoTransmit,
                      status: SolarStatus.ok,
                    ),
                    const SizedBox(height: SolarSpace.md),
                    HexGrid(
                      title: l10n.evidence,
                      bytes: Uint8List.fromList(const [1, 3, 0, 0, 0, 2]),
                    ),
                    const SizedBox(height: SolarSpace.md),
                    HypothesisCard(
                      title: l10n.evidence,
                      detail: l10n.registerMapRequired,
                    ),
                  ],
                ),
              ),
              _Section(
                title: l10n.symbols,
                child: const Column(
                  children: [
                    _AnimatedIconStates(),
                    SizedBox(height: SolarSpace.lg),
                    _IconGallery(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: SolarSpace.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: SolarSpace.lg),
        child,
      ],
    ),
  );
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip();
  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<SolarTokens>()!.palette;
    final colors = [p.tint, p.ok, p.warning, p.critical, p.info, p.simulated];
    return Wrap(
      spacing: SolarSpace.sm,
      runSpacing: SolarSpace.sm,
      children: [
        for (final color in colors)
          Semantics(
            label: color.toARGB32().toRadixString(16),
            child: Container(
              width: 88,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(SolarRadius.control),
              ),
            ),
          ),
      ],
    );
  }
}

class _IconGallery extends StatelessWidget {
  const _IconGallery();
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 150,
      mainAxisExtent: 88,
      crossAxisSpacing: SolarSpace.sm,
      mainAxisSpacing: SolarSpace.sm,
    ),
    itemCount: SolarIcons.all.length,
    itemBuilder: (context, index) {
      final icon = SolarIcons.all[index];
      return SolarSurface(
        padding: const EdgeInsets.all(SolarSpace.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SolarIcon(icon, size: 24, semanticLabel: icon.name),
            const SizedBox(height: SolarSpace.sm),
            Text(
              icon.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    },
  );
}

class _AnimatedIconStates extends StatelessWidget {
  const _AnimatedIconStates();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: SolarSpace.xxl,
    runSpacing: SolarSpace.md,
    children: const [
      SolarAnimatedIcon(
        icon: SolarIcons.balancing,
        state: SolarAnimatedIconState.balancing,
        semanticLabel: 'balancing',
      ),
      SolarAnimatedIcon(
        icon: SolarIcons.battery,
        state: SolarAnimatedIconState.charging,
        semanticLabel: 'charging',
      ),
      SolarAnimatedIcon(
        icon: SolarIcons.currentFlow,
        state: SolarAnimatedIconState.linkPulse,
        semanticLabel: 'link pulse',
      ),
      SolarAnimatedIcon(
        icon: SolarIcons.search,
        state: SolarAnimatedIconState.scanning,
        semanticLabel: 'scanning',
      ),
    ],
  );
}
