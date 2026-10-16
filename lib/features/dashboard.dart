import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../core/battery_models.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.snapshot,
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
    required this.onOpenDesignLab,
  });
  final BatterySnapshot snapshot;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenDesignLab;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _Rail(onOpenDesignLab: onOpenDesignLab),
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
                        _Hero(snapshot: snapshot),
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
      bottomNavigationBar: !wide
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
      floatingActionButton: !wide
          ? FloatingActionButton.small(
              onPressed: onOpenDesignLab,
              tooltip: s.designLab,
              child: const Icon(Icons.science_outlined),
            )
          : null,
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
            child: Icon(icon, color: Colors.white54),
          ),
        IconButton(
          onPressed: onOpenDesignLab,
          tooltip: AppStrings.of(context).designLab,
          icon: const Icon(Icons.science_outlined, color: Colors.white54),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 26),
          child: Icon(Icons.settings_outlined, color: Colors.white54),
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
    final s = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'SOLARDIAG PRO',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: SolarColors.green,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleLocale,
              tooltip: s.pick('Arabic', 'English'),
              icon: const Icon(Icons.language),
            ),
            IconButton(
              onPressed: onToggleTheme,
              tooltip: s.pick('Toggle theme', 'تبديل المظهر'),
              icon: const Icon(Icons.contrast),
            ),
            IconButton(
              onPressed: onToggleContrast,
              tooltip: s.pick('High contrast', 'تباين عالٍ'),
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
  const _Hero({required this.snapshot});
  final BatterySnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(s.healthy, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          _BigMetric(value: snapshot.soc, label: s.soc),
          _BigMetric(value: snapshot.voltage, label: s.packVoltage),
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
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value.isReported
              ? '${value.value!.toStringAsFixed(value.unit == '%' ? 0 : 2)} ${value.unit}'
              : AppStrings.of(context).missing,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
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
    final s = AppStrings.of(context);
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
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value.isReported
                  ? '${value.value!.toStringAsFixed(1)} ${value.unit}'
                  : AppStrings.of(context).missing,
              style: value.isReported
                  ? Theme.of(context).textTheme.headlineSmall
                  : TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
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
    final s = AppStrings.of(context);
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
                        Text(
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
