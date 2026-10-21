import 'package:flutter/material.dart';

import '../core/battery_models.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/device_session.dart';

enum BatterySection {
  overview,
  cells,
  temperature,
  faults,
  balancing,
  health,
  service,
  reports,
  parallel,
}

class BatteryWorkspace extends StatefulWidget {
  const BatteryWorkspace({super.key});

  @override
  State<BatteryWorkspace> createState() => _BatteryWorkspaceState();
}

class _BatteryWorkspaceState extends State<BatteryWorkspace> {
  BatterySection section = BatterySection.overview;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final snapshot = DeviceSessionScope.of(context).snapshot;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
        children: [
          Text(
            s.batteryBmsDiagnostics,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(s.batteryWorkspaceDescription),
          const SizedBox(height: 18),
          SingleChildScrollView(
            key: const Key('battery-section-scroll'),
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<BatterySection>(
              segments: [
                ButtonSegment(
                  value: BatterySection.overview,
                  icon: const Icon(Icons.dashboard_outlined),
                  label: Text(s.overview),
                ),
                ButtonSegment(
                  value: BatterySection.cells,
                  icon: const Icon(Icons.grid_view_outlined),
                  label: Text(s.cellMonitoring),
                ),
                ButtonSegment(
                  value: BatterySection.temperature,
                  icon: const Icon(Icons.thermostat_outlined),
                  label: Text(s.temperature),
                ),
                ButtonSegment(
                  value: BatterySection.faults,
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: Text(s.faultDiagnostics),
                ),
                ButtonSegment(
                  value: BatterySection.balancing,
                  icon: const Icon(Icons.balance),
                  label: Text(s.cellBalancing),
                ),
                ButtonSegment(
                  value: BatterySection.health,
                  icon: const Icon(Icons.monitor_heart_outlined),
                  label: Text(s.batteryHealth),
                ),
                ButtonSegment(
                  value: BatterySection.service,
                  icon: const Icon(Icons.build_outlined),
                  label: Text(s.serviceFunctions),
                ),
                ButtonSegment(
                  value: BatterySection.reports,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(s.reports),
                ),
                ButtonSegment(
                  value: BatterySection.parallel,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: Text(s.parallelBank),
                ),
              ],
              selected: {section},
              onSelectionChanged: (value) =>
                  setState(() => section = value.single),
            ),
          ),
          const SizedBox(height: 22),
          switch (section) {
            BatterySection.overview => _Overview(snapshot),
            BatterySection.cells => _Cells(snapshot),
            BatterySection.temperature => _Temperatures(snapshot),
            BatterySection.faults => const _Faults(),
            BatterySection.balancing => _Balancing(snapshot),
            BatterySection.health => _Health(snapshot),
            BatterySection.service => const _ServiceFunctions(),
            BatterySection.reports => const _Reports(),
            BatterySection.parallel => const _ParallelBank(),
          },
        ],
      ),
    );
  }
}

class _Balancing extends StatelessWidget {
  const _Balancing(this.snapshot);
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final mask = snapshot.balancingMask;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MeasurementCard(s.balancingMask, mask),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              mask.value == null
                  ? s.balancingUnavailable
                  : mask.value == 0
                  ? s.noCellsBalancing
                  : s.balancingReportedActive,
            ),
            subtitle: Text(s.balancingEvidenceNote),
          ),
        ),
      ],
    );
  }
}

class _Health extends StatelessWidget {
  const _Health(this.snapshot);
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MeasurementCard(s.stateOfHealth, snapshot.soh),
            _MeasurementCard(s.cycleCount, snapshot.cycleCount),
            _MeasurementCard(s.fullChargeCapacity, snapshot.fullChargeCapacity),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(s.healthMethodNote),
          ),
        ),
      ],
    );
  }
}

class _ServiceFunctions extends StatelessWidget {
  const _ServiceFunctions();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      children: [
        _LockedService(
          title: s.configurationParameters,
          detail: s.simulatedWriteOnly,
          icon: Icons.tune,
        ),
        _LockedService(
          title: s.calibration,
          detail: s.noVerifiedCalibrationProcedure,
          icon: Icons.straighten_outlined,
        ),
        _LockedService(
          title: s.factoryFunctions,
          detail: s.factoryFunctionsUnavailable,
          icon: Icons.factory_outlined,
        ),
      ],
    );
  }
}

class _LockedService extends StatelessWidget {
  const _LockedService({
    required this.title,
    required this.detail,
    required this.icon,
  });
  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(detail),
      trailing: const Icon(Icons.lock_outline),
    ),
  );
}

class _Reports extends StatelessWidget {
  const _Reports();

  @override
  Widget build(BuildContext context) =>
      _Unavailable(AppLocalizations.of(context).reportsAvailableFromHistory);
}

class _ParallelBank extends StatelessWidget {
  const _ParallelBank();

  @override
  Widget build(BuildContext context) => _Unavailable(
    AppLocalizations.of(context).parallelModuleTelemetryUnavailable,
  );
}

class _Overview extends StatelessWidget {
  const _Overview(this.snapshot);
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MeasurementCard(s.stateOfCharge, snapshot.soc),
        _MeasurementCard(s.packVoltage, snapshot.voltage),
        _MeasurementCard(s.current, snapshot.current),
        _MeasurementCard(s.power, snapshot.power),
        _MeasurementCard(s.stateOfHealth, snapshot.soh),
        _MeasurementCard(s.cycleCount, snapshot.cycleCount),
      ],
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells(this.snapshot);
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final cells = [
      for (var i = 0; i < snapshot.cellMeasurements.length; i++)
        if (snapshot.cellMeasurements[i].value case final value?)
          (index: i, value: value),
    ]..sort((a, b) => a.value.compareTo(b.value));
    if (cells.isEmpty) return _Unavailable(s.noCellReadings);
    final minimum = cells.first;
    final maximum = cells.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              s.minimumCell,
              s.cellVoltageValue(
                minimum.index + 1,
                minimum.value.toStringAsFixed(3),
              ),
            ),
            _SummaryCard(
              s.maximumCell,
              s.cellVoltageValue(
                maximum.index + 1,
                maximum.value.toStringAsFixed(3),
              ),
            ),
            _SummaryCard(
              s.cellDelta,
              '${((maximum.value - minimum.value) * 1000).toStringAsFixed(1)} mV',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cell in cells)
              SizedBox(
                width: 132,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(s.cellNumber(cell.index + 1)),
                        const SizedBox(height: 6),
                        Text(
                          '${cell.value.toStringAsFixed(3)} V',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Temperatures extends StatelessWidget {
  const _Temperatures(this.snapshot);
  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (snapshot.temperatureSensors.isEmpty) {
      return _Unavailable(s.temperatureUnavailableDetail);
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final sensor in snapshot.temperatureSensors)
          _MeasurementCard(
            '${sensor.label} · ${sensor.kind.name}',
            sensor.measurement,
          ),
      ],
    );
  }
}

class _Faults extends StatelessWidget {
  const _Faults();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final alarms = DeviceSessionScope.of(context).alarmCodes;
    if (alarms.isEmpty) return _Unavailable(s.noActiveAlarms);
    return Column(
      children: [
        for (final code in alarms)
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(switch (code) {
                'CELL_OVERVOLTAGE' => s.cellOvervoltageAlarm,
                'CELL_OVERTEMPERATURE' => s.temperatureHigh,
                _ => s.unrecognizedAlarm,
              }),
              subtitle: Text(s.rawAlarmCode(code)),
            ),
          ),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard(this.label, this.value);
  final String label;
  final Measurement value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                value.value == null
                    ? AppLocalizations.of(context).notReportedByDevice
                    : '${value.value!.toStringAsFixed(1)} ${value.unit}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
