import 'package:flutter/material.dart';

import '../core/battery_models.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/device_session.dart';

class InverterDiagnosticsScreen extends StatelessWidget {
  const InverterDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final snapshot = DeviceSessionScope.of(context).inverterSnapshot;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
        children: [
          Text(
            s.inverterDiagnostics,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(s.inverterDiagnosticsDescription),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(s.simulatedInverterProfile),
              subtitle: Text(s.simulatedInverterEvidence),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(s.freconResearchProfile),
              subtitle: Text(s.registerMapRequired),
            ),
          ),
          const SizedBox(height: 20),
          if (snapshot == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(s.waitingForInverterTelemetry),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ReadingCard(label: s.dcVoltage, reading: snapshot.dcVoltage),
                _ReadingCard(label: s.dcCurrent, reading: snapshot.dcCurrent),
                _ReadingCard(label: s.dcPower, reading: snapshot.dcPower),
                _ReadingCard(label: s.acVoltage, reading: snapshot.acVoltage),
                _ReadingCard(label: s.acCurrent, reading: snapshot.acCurrent),
                _ReadingCard(label: s.acPower, reading: snapshot.acPower),
                _ReadingCard(label: s.frequency, reading: snapshot.frequency),
                _ReadingCard(
                  label: s.temperature,
                  reading: snapshot.temperature,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.label, required this.reading});

  final String label;
  final Measurement reading;

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
            Text(
              reading.value == null
                  ? AppLocalizations.of(context).notReportedByDevice
                  : '${reading.value!.toStringAsFixed(1)} ${reading.unit}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    ),
  );
}
