import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../core/battery_models.dart';
import '../design/components.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../design/accessibility.dart';
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
  const BatteryWorkspace({
    super.key,
    this.initialSection = BatterySection.overview,
  });

  final BatterySection initialSection;

  @override
  State<BatteryWorkspace> createState() => _BatteryWorkspaceState();
}

class _BatteryWorkspaceState extends State<BatteryWorkspace> {
  late BatterySection section = widget.initialSection;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final snapshot = DeviceSessionScope.of(context).snapshot;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
        children: [
          PrecisionPageHeading(
            title: s.batteryBmsDiagnostics,
            subtitle: s.batteryWorkspaceDescription,
            icon: SolarIcons.battery,
          ),
          const SizedBox(height: 18),
          PrecisionCard(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                key: const Key('battery-section-scroll'),
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<BatterySection>(
                  segments: [
                    ButtonSegment(
                      value: BatterySection.overview,
                      icon: const SolarIcon(SolarIcons.home),
                      label: Text(s.overview),
                    ),
                    ButtonSegment(
                      value: BatterySection.cells,
                      icon: const SolarIcon(SolarIcons.cellGrid),
                      label: Text(s.cellMonitoring),
                    ),
                    ButtonSegment(
                      value: BatterySection.temperature,
                      icon: const SolarIcon(SolarIcons.temperature),
                      label: Text(s.temperature),
                    ),
                    ButtonSegment(
                      value: BatterySection.faults,
                      icon: const SolarIcon(SolarIcons.warning),
                      label: Text(s.faultDiagnostics),
                    ),
                    ButtonSegment(
                      value: BatterySection.balancing,
                      icon: const SolarIcon(SolarIcons.balancing),
                      label: Text(s.cellBalancing),
                    ),
                    ButtonSegment(
                      value: BatterySection.health,
                      icon: const SolarIcon(SolarIcons.soh),
                      label: Text(s.batteryHealth),
                    ),
                    ButtonSegment(
                      value: BatterySection.service,
                      icon: const SolarIcon(SolarIcons.configure),
                      label: Text(s.serviceFunctions),
                    ),
                    ButtonSegment(
                      value: BatterySection.reports,
                      icon: const SolarIcon(SolarIcons.report),
                      label: Text(s.reports),
                    ),
                    ButtonSegment(
                      value: BatterySection.parallel,
                      icon: const SolarIcon(SolarIcons.parallelBank),
                      label: Text(s.parallelBank),
                    ),
                  ],
                  selected: {section},
                  onSelectionChanged: (value) =>
                      setState(() => section = value.single),
                ),
              ),
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
        PrecisionCard(
          child: ListTile(
            leading: mask.value != null && mask.value != 0
                ? const SolarAnimatedIcon(
                    icon: SolarIcons.balancing,
                    state: SolarAnimatedIconState.balancing,
                  )
                : const SolarIcon(SolarIcons.evidence),
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
            _MeasurementCard(
              s.cycleCount,
              snapshot.cycleCount,
              fractionDigits: 0,
            ),
            _MeasurementCard(s.fullChargeCapacity, snapshot.fullChargeCapacity),
          ],
        ),
        const SizedBox(height: 12),
        PrecisionCard(
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
          icon: SolarIcons.configure,
        ),
        _LockedService(
          title: s.calibration,
          detail: s.noVerifiedCalibrationProcedure,
          icon: SolarIcons.calibrate,
        ),
        _LockedService(
          title: s.factoryFunctions,
          detail: s.factoryFunctionsUnavailable,
          icon: SolarIcons.factory,
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
  final SolarIconData icon;

  @override
  Widget build(BuildContext context) => PrecisionCard(
    child: ListTile(
      leading: SolarIcon(icon),
      title: Text(title),
      subtitle: Text(detail),
      trailing: const SolarIcon(SolarIcons.locked),
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
        _MeasurementCard(s.cycleCount, snapshot.cycleCount, fractionDigits: 0),
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
    final orderedValues = snapshot.cellMeasurements
        .map((measurement) => measurement.value)
        .nonNulls
        .toList();
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
                localizedNumber(context, minimum.value, fractionDigits: 3),
              ),
            ),
            _SummaryCard(
              s.maximumCell,
              s.cellVoltageValue(
                maximum.index + 1,
                localizedNumber(context, maximum.value, fractionDigits: 3),
              ),
            ),
            _SummaryCard(
              s.cellDelta,
              localizedMeasurement(
                context,
                (maximum.value - minimum.value) * 1000,
                'mV',
                fractionDigits: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final columns = constraints.maxWidth >= 600 ? 2 : 1;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final cell in cells)
                  SizedBox(
                    key: Key('battery-cell-card-${cell.index + 1}'),
                    width: cardWidth,
                    child: PrecisionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(s.cellNumber(cell.index + 1)),
                            const SizedBox(height: 6),
                            Text(
                              localizedMeasurement(
                                context,
                                cell.value,
                                'V',
                                fractionDigits: 3,
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        CellGrid(values: orderedValues),
        const SizedBox(height: 18),
        CellBarChart(values: orderedValues),
        const SizedBox(height: 18),
        CellHeatmap(values: orderedValues),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThermalMap(label: s.temperature, readings: snapshot.temperatureSensors),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final sensor in snapshot.temperatureSensors)
              _MeasurementCard(
                '${sensor.label} · ${sensor.kind.name}',
                sensor.measurement,
              ),
          ],
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
        for (final code in alarms) ...[
          Semantics(
            liveRegion: true,
            label:
                '${switch (code) {
                  'CELL_OVERVOLTAGE' => s.cellOvervoltageAlarm,
                  'CELL_OVERTEMPERATURE' => s.temperatureHigh,
                  _ => s.unrecognizedAlarm,
                }}, ${s.rawAlarmCode(code)}',
            child: ExcludeSemantics(
              child: PrecisionCard(
                child: ListTile(
                  leading: const SolarIcon(SolarIcons.warning),
                  title: Text(switch (code) {
                    'CELL_OVERVOLTAGE' => s.cellOvervoltageAlarm,
                    'CELL_OVERTEMPERATURE' => s.temperatureHigh,
                    _ => s.unrecognizedAlarm,
                  }),
                  subtitle: Text(s.rawAlarmCode(code)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard(this.label, this.value, {this.fractionDigits});
  final String label;
  final Measurement value;
  final int? fractionDigits;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final numericValue = value.value;
    final valueLabel = numericValue == null
        ? s.notReportedByDevice
        : localizedMeasurement(
            context,
            numericValue,
            value.unit,
            fractionDigits: fractionDigits,
          );
    final freshness = numericValue == null
        ? s.telemetryUnavailable
        : value.quality == MeasurementQuality.stale
        ? s.measurementStale
        : value.timestamp == null
        ? s.updatedNow
        : s.measurementCapturedAt(value.timestamp!.toUtc().toIso8601String());
    return SizedBox(
      width: 220,
      child: PrecisionReading(
        label: label,
        value: valueLabel,
        freshness: freshness,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: PrecisionReading(label: label, value: value),
  );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => PrecisionCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SolarIcon(SolarIcons.evidence),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
