import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../design/accessibility.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/battery_models.dart';
import '../session/device_session.dart';
import '../simulator/simulation_scenario.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
    required this.onOpenDesignLab,
    required this.onOpenDiagnostics,
    required this.onOpenSettings,
    this.onSelectDestination,
    this.embedded = false,
  });
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenDesignLab;
  final VoidCallback onOpenDiagnostics;
  final VoidCallback onOpenSettings;
  final ValueChanged<int>? onSelectDestination;
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final snapshot = session.snapshot;
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide && !embedded) _Rail(onOpenDesignLab: onOpenDesignLab),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 44 : 20,
                      24,
                      wide ? 44 : 20,
                      56,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _Header(
                          onToggleLocale: onToggleLocale,
                          onToggleTheme: onToggleTheme,
                          onToggleContrast: onToggleContrast,
                          onOpenSettings: onOpenSettings,
                        ),
                        const SizedBox(height: 32),
                        DropdownButtonFormField<SimulationScenario>(
                          key: const Key('scenario-selector'),
                          initialValue: session.scenario,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: s.simulatedScenario,
                          ),
                          items: [
                            for (final item in SimulationScenario.values)
                              DropdownMenuItem(
                                value: item,
                                child: Text(item.name),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) session.selectScenario(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _Hero(snapshot: snapshot, linkState: session.linkState),
                        const SizedBox(height: 20),
                        _DestinationGrid(
                          session: session,
                          onSelectDestination: onSelectDestination,
                        ),
                        const SizedBox(height: 20),
                        _RecentSessions(session: session),
                        const SizedBox(height: 14),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FilledButton.icon(
                            onPressed: onOpenDiagnostics,
                            icon: const SolarIcon(SolarIcons.soh),
                            label: Text(s.openAdvancedDiagnostics),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Metrics(snapshot: snapshot),
                        const SizedBox(height: 20),
                        _CellPanel(snapshot: snapshot),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !wide && !embedded
          ? NavigationBar(
              selectedIndex: 0,
              destinations: [
                NavigationDestination(
                  icon: const SolarIcon(SolarIcons.home),
                  label: s.overview,
                ),
                NavigationDestination(
                  icon: const SolarIcon(SolarIcons.battery),
                  label: s.battery,
                ),
                NavigationDestination(
                  icon: const SolarIcon(SolarIcons.gateway),
                  label: s.gateway,
                ),
              ],
            )
          : null,
      floatingActionButton: !wide && !embedded
          ? FloatingActionButton.small(
              onPressed: onOpenDesignLab,
              tooltip: s.designLab,
              child: const SolarIcon(SolarIcons.research),
            )
          : null,
    );
  }
}

class _DestinationGrid extends StatelessWidget {
  const _DestinationGrid({
    required this.session,
    required this.onSelectDestination,
  });

  final DeviceSession session;
  final ValueChanged<int>? onSelectDestination;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final online = session.linkState == DeviceSessionLinkState.online;
    final items = [
      (
        s.inverterDiagnostics,
        s.simulatedTelemetryActive,
        SolarIcons.inverter,
        () => onSelectDestination?.call(1),
      ),
      (
        s.batteryBmsDiagnostics,
        online ? s.liveTelemetryActive : s.telemetryUnavailable,
        SolarIcons.battery,
        () => onSelectDestination?.call(2),
      ),
      (
        s.inverterBatteryLink,
        online ? s.linkEvidenceAvailable : s.deliveryUnavailable,
        SolarIcons.linkDiagnostics,
        () => onSelectDestination?.call(4),
      ),
      (
        s.deviceLibrary,
        s.verificationStatusVisible,
        SolarIcons.library,
        () => onSelectDestination?.call(3),
      ),
      (
        s.diagnosticHistory,
        s.savedSessionCount(session.history.length),
        SolarIcons.history,
        () => onSelectDestination?.call(7),
      ),
      (
        s.diagnosticGateway,
        online ? s.listenOnly : s.linkUnavailable,
        SolarIcons.gateway,
        () => onSelectDestination?.call(5),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Card(
                  child: InkWell(
                    key: ValueKey('destination-${item.$1}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: item.$4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          SolarIcon(item.$3),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$1,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(item.$2),
                              ],
                            ),
                          ),
                          const SolarIcon(SolarIcons.currentFlow),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions({required this.session});

  final DeviceSession session;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final recent = session.history.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.recentSessions,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(s.noSavedSessions),
            ),
          )
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final record = recent[index];
                return SizedBox(
                  width: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.scenarioValue(record.scenario)),
                          const Spacer(),
                          Text(
                            s.integrityHashValue(
                              record.dataHash.substring(0, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.onOpenDesignLab});
  final VoidCallback onOpenDesignLab;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      width: 92,
      color: palette.labelPrimary,
      child: Column(
        children: [
          const SizedBox(height: 28),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.simulated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SolarIcon(SolarIcons.solar, color: palette.background),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: SolarIcon(SolarIcons.home, color: palette.simulated),
          ),
          for (final icon in [SolarIcons.battery, SolarIcons.gateway])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: SolarIcon(
                icon,
                color: palette.background.withValues(alpha: .54),
              ),
            ),
          IconButton(
            onPressed: onOpenDesignLab,
            tooltip: AppLocalizations.of(context).designLab,
            icon: SolarIcon(
              SolarIcons.research,
              color: palette.background.withValues(alpha: .54),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 26),
            child: SolarIcon(
              SolarIcons.configure,
              color: palette.background.withValues(alpha: .54),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
    required this.onOpenSettings,
  });
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenSettings;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).appTitle.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: palette.tint,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('toggle-locale'),
              onPressed: onToggleLocale,
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? s.english
                  : s.arabic,
              icon: const SolarIcon(SolarIcons.role),
            ),
            IconButton(
              key: const Key('toggle-theme'),
              onPressed: onToggleTheme,
              tooltip: s.toggleTheme,
              icon: const SolarIcon(SolarIcons.compare),
            ),
            IconButton(
              onPressed: onToggleContrast,
              tooltip: s.highContrast,
              icon: const SolarIcon(SolarIcons.evidence),
            ),
            IconButton(
              onPressed: onOpenSettings,
              tooltip: s.settings,
              icon: const SolarIcon(SolarIcons.configure),
            ),
            _Pill(icon: SolarIcons.readOnly, text: s.readOnly),
          ],
        ),
        const SizedBox(height: 7),
        Text(s.tagline, style: Theme.of(context).textTheme.displaySmall),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.snapshot, required this.linkState});
  final BatterySnapshot snapshot;
  final DeviceSessionLinkState linkState;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.labelPrimary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Wrap(
        spacing: 42,
        runSpacing: 28,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pill(icon: SolarIcons.simulated, text: s.simulated),
                const SizedBox(height: 24),
                Text(
                  s.bank,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: palette.background,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  switch (linkState) {
                    DeviceSessionLinkState.connecting => s.connecting,
                    DeviceSessionLinkState.online => s.online,
                    DeviceSessionLinkState.unavailable => s.linkUnavailable,
                  },
                  style: TextStyle(
                    color: palette.background.withValues(alpha: .62),
                  ),
                ),
              ],
            ),
          ),
          _BigMetric(value: snapshot.soc, label: s.stateOfCharge.toUpperCase()),
          _BigMetric(
            value: snapshot.voltage,
            label: s.packVoltage.toUpperCase(),
          ),
        ],
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  const _BigMetric({required this.value, required this.label});
  final Measurement value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final valueLabel = value.isReported
        ? '${localizedNumber(context, value.value!, fractionDigits: value.unit == '%' ? 0 : 2)} ${value.unit}'
        : AppLocalizations.of(context).notReportedByDevice;
    return Semantics(
      label: '$label, $valueLabel',
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: palette.background.withValues(alpha: .54),
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 7),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                valueLabel,
                style: TextStyle(
                  color: palette.background,
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.snapshot});
  final BatterySnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          title: s.current,
          value: snapshot.current,
          icon: SolarIcons.currentFlow,
        ),
        _MetricCard(
          title: s.temperature,
          value: snapshot.temperature,
          icon: SolarIcons.temperature,
        ),
        _MetricCard(
          title: s.cellDelta,
          value: snapshot.cellDelta == null
              ? const Measurement.absent(DataAbsenceReason.notReported)
              : Measurement.value(snapshot.cellDelta! * 1000, 'mV'),
          icon: SolarIcons.balancing,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final Measurement value;
  final SolarIconData icon;
  @override
  Widget build(BuildContext context) {
    final valueLabel = value.isReported
        ? '${localizedNumber(context, value.value!, fractionDigits: 1)} ${value.unit}'
        : AppLocalizations.of(context).notReportedByDevice;
    return Semantics(
      label: '$title, $valueLabel',
      child: SizedBox(
        width: 230,
        height: 148,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SolarIcon(
                      icon,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).extension<SolarTokens>()!.palette.tint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    valueLabel,
                    style: value.isReported
                        ? Theme.of(context).textTheme.headlineSmall
                        : TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CellPanel extends StatelessWidget {
  const _CellPanel({required this.snapshot});
  final BatterySnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.cellBalance,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              s.rawValues,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (var i = 0; i < snapshot.cellVoltages.length; i++)
                  Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        TechnicalText(
                          _cellLabel(i),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          localizedNumber(
                            context,
                            snapshot.cellVoltages[i],
                            fractionDigits: 3,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _cellLabel(int index) => 'C${index + 1}';

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final SolarIconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.simulated,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SolarIcon(icon, size: 15, color: palette.labelPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: palette.labelPrimary,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}
