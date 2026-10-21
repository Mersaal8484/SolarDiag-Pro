import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../design/accessibility.dart';
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
    this.onSelectDestination,
    this.embedded = false,
  });
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenDesignLab;
  final VoidCallback onOpenDiagnostics;
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
                            icon: const Icon(Icons.monitor_heart_outlined),
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
                  icon: const Icon(Icons.grid_view),
                  label: s.overview,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.battery_6_bar),
                  label: s.battery,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.cable),
                  label: s.gateway,
                ),
              ],
            )
          : null,
      floatingActionButton: !wide && !embedded
          ? FloatingActionButton.small(
              onPressed: onOpenDesignLab,
              tooltip: s.designLab,
              child: const Icon(Icons.science_outlined),
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
        Icons.solar_power_outlined,
        () => onSelectDestination?.call(1),
      ),
      (
        s.batteryBmsDiagnostics,
        online ? s.liveTelemetryActive : s.telemetryUnavailable,
        Icons.battery_6_bar,
        () => onSelectDestination?.call(2),
      ),
      (
        s.inverterBatteryLink,
        online ? s.linkEvidenceAvailable : s.deliveryUnavailable,
        Icons.link,
        () => onSelectDestination?.call(4),
      ),
      (
        s.deviceLibrary,
        s.verificationStatusVisible,
        Icons.library_books_outlined,
        () => onSelectDestination?.call(3),
      ),
      (
        s.diagnosticHistory,
        s.savedSessionCount(session.history.length),
        Icons.history,
        () => onSelectDestination?.call(7),
      ),
      (
        s.diagnosticGateway,
        online ? s.listenOnly : s.linkUnavailable,
        Icons.cable,
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
                          Icon(item.$3),
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
                          const Icon(Icons.chevron_right),
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
  Widget build(BuildContext context) => Container(
    width: 92,
    color: SolarColors.deep,
    child: Column(
      children: [
        const SizedBox(height: 28),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: SolarColors.lime,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt, color: SolarColors.deep),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Icon(Icons.grid_view, color: SolarColors.lime),
        ),
        for (final icon in [Icons.battery_6_bar, Icons.cable])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Icon(icon, color: SolarColors.onDarkFaint),
          ),
        IconButton(
          onPressed: onOpenDesignLab,
          tooltip: AppLocalizations.of(context).designLab,
          icon: const Icon(
            Icons.science_outlined,
            color: SolarColors.onDarkFaint,
          ),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 26),
          child: Icon(Icons.settings_outlined, color: SolarColors.onDarkFaint),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
  });
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
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
                color: SolarColors.green,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleLocale,
              tooltip: Localizations.localeOf(context).languageCode == 'ar'
                  ? s.english
                  : s.arabic,
              icon: const Icon(Icons.language),
            ),
            IconButton(
              onPressed: onToggleTheme,
              tooltip: s.toggleTheme,
              icon: const Icon(Icons.contrast),
            ),
            IconButton(
              onPressed: onToggleContrast,
              tooltip: s.highContrast,
              icon: const Icon(Icons.visibility_outlined),
            ),
            _Pill(icon: Icons.shield_outlined, text: s.readOnly),
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: SolarColors.deep,
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
                _Pill(icon: Icons.science_outlined, text: s.simulated),
                const SizedBox(height: 24),
                Text(
                  s.bank,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: SolarColors.onDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(switch (linkState) {
                  DeviceSessionLinkState.connecting => s.connecting,
                  DeviceSessionLinkState.online => s.online,
                  DeviceSessionLinkState.unavailable => s.linkUnavailable,
                }, style: const TextStyle(color: SolarColors.onDarkMuted)),
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
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SolarColors.onDarkFaint,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            value.isReported
                ? '${value.value!.toStringAsFixed(value.unit == '%' ? 0 : 2)} ${value.unit}'
                : AppLocalizations.of(context).notReportedByDevice,
            style: const TextStyle(
              color: SolarColors.onDark,
              fontSize: 31,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
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
          icon: Icons.swap_vert,
        ),
        _MetricCard(
          title: s.temperature,
          value: snapshot.temperature,
          icon: Icons.thermostat_outlined,
        ),
        _MetricCard(
          title: s.cellDelta,
          value: snapshot.cellDelta == null
              ? const Measurement.absent(DataAbsenceReason.notReported)
              : Measurement.value(snapshot.cellDelta! * 1000, 'mV'),
          icon: Icons.balance,
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
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
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
                Icon(icon, size: 20, color: SolarColors.green),
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
                value.isReported
                    ? '${value.value!.toStringAsFixed(1)} ${value.unit}'
                    : AppLocalizations.of(context).notReportedByDevice,
                style: value.isReported
                    ? Theme.of(context).textTheme.headlineSmall
                    : TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
                          'C${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          snapshot.cellVoltages[i].toStringAsFixed(3),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: SolarColors.lime,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: SolarColors.deep),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: SolarColors.deep,
            letterSpacing: .6,
          ),
        ),
      ],
    ),
  );
}
