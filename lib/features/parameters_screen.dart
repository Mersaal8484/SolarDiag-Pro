import 'dart:async';

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../parameters/parameter_models.dart';
import '../session/device_session.dart';

class ParametersScreen extends StatefulWidget {
  const ParametersScreen({super.key});

  @override
  State<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends State<ParametersScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    unawaited(DeviceSessionScope.of(context).refreshParameters());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final entries = session.parameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(s.parameters, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(s.simulatorValuesNotice),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SolarColors.deep,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(Icons.science_outlined, color: SolarColors.lime),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.simulatedWritePipeline,
                  style: const TextStyle(
                    color: SolarColors.onDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          Text(s.noParametersReported)
        else
          for (final entry in entries)
            _ParameterTile(
              title: _label(s, entry.key),
              value: _value(entry.key, entry.value),
              range: _range(entry.key),
              onEdit: entry.key == 'charge_limit'
                  ? () => _editParameter(
                      session: session,
                      id: entry.key,
                      before: entry.value,
                    )
                  : null,
            ),
        const SizedBox(height: 16),
        Text(s.backupsSaved(session.backups.length)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: entries.isEmpty
                  ? null
                  : () {
                      session.createParameterBackup();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(s.backupCreated)));
                    },
              icon: const Icon(Icons.backup_outlined),
              label: Text(s.createBackup),
            ),
            OutlinedButton.icon(
              key: const Key('restore-latest-backup'),
              onPressed: session.backups.isEmpty
                  ? null
                  : () => _restoreBackup(session),
              icon: const Icon(Icons.restore),
              label: Text(s.restoreLatestBackup),
            ),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.edit_off_outlined),
              label: Text(s.physicalWriteLocked),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _restoreBackup(DeviceSession session) async {
    final s = AppLocalizations.of(context);
    final backup = session.backups.first;
    final changes = backup.planRestore(
      activeProfileId: 'solardiag.simulated.lfp16.v2',
      activeDeviceIdentity: 'SOLARDIAG-SIM-BMS',
      activeFirmware: 'simulator-v2',
      definitions: DeviceSession.parameterDefinitions,
      current: ParameterSnapshot(
        session.parameters,
        capturedAt: DateTime.now().toUtc(),
      ),
    );
    if (changes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.backupAlreadyMatches)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.restoreBackup),
        content: Text(s.restoreBackupConfirmation(changes.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            key: const Key('confirm-backup-restore'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.confirmRestore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final results = await session.restoreParameterBackup(backup);
    if (!mounted) return;
    final applied = results.where(
      (result) => result.outcome == WriteOutcome.applied,
    );
    final success = applied.length == changes.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? s.backupRestoreComplete(applied.length)
              : s.backupRestoreFailed,
        ),
      ),
    );
  }

  Future<void> _editParameter({
    required DeviceSession session,
    required String id,
    required num before,
  }) async {
    final s = AppLocalizations.of(context);
    final definition = DeviceSession.parameterDefinitions[id]!;
    var requested = before.toDouble();
    var acknowledged = false;
    final confirmed = await showDialog<num>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(s.reviewChanges),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label(s, id)),
                const SizedBox(height: 8),
                Text(
                  '${_value(id, before)} → ${_value(id, requested)}',
                  key: const Key('parameter-diff'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Slider(
                  key: const Key('parameter-slider'),
                  value: requested,
                  min: definition.minimum.toDouble(),
                  max: definition.maximum.toDouble(),
                  divisions:
                      ((definition.maximum - definition.minimum) /
                              definition.step)
                          .round(),
                  label: _value(id, requested),
                  onChanged: (value) => setDialogState(
                    () => requested = double.parse(value.toStringAsFixed(1)),
                  ),
                ),
                Text(s.parameterRiskAdvanced),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acknowledged,
                  title: Text(s.safetyAcknowledgement),
                  onChanged: (value) =>
                      setDialogState(() => acknowledged = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.cancel),
            ),
            FilledButton(
              key: const Key('confirm-parameter-write'),
              onPressed: acknowledged
                  ? () => Navigator.pop(dialogContext, requested)
                  : null,
              child: Text(s.confirmSimulatedWrite),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;
    final result = await session.applySimulatedParameterChange(
      parameterId: id,
      requestedValue: confirmed,
      safetyAcknowledged: true,
    );
    if (!mounted) return;
    final message = switch (result.outcome) {
      WriteOutcome.applied => s.writeAppliedWithReadback(
        _value(id, result.readback!),
      ),
      WriteOutcome.rejected => s.writeRejected,
      WriteOutcome.failed => s.writeFailedVerify,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _label(AppLocalizations s, String id) => switch (id) {
    'charge_limit' => s.chargeVoltageLimit,
    'service_mode' => s.serviceMode,
    _ => id.replaceAll('_', ' '),
  };

  static String _value(String id, num value) {
    final definition = DeviceSession.parameterDefinitions[id];
    final unit = definition?.unit ?? '';
    return [value, if (unit.isNotEmpty) unit].join(' ');
  }

  static String _range(String id) {
    final definition = DeviceSession.parameterDefinitions[id];
    if (definition == null) return id;
    final unit = definition.unit;
    return '${definition.minimum}–${definition.maximum}'
        '${unit.isEmpty ? '' : ' $unit'} · ${definition.step}'
        '${unit.isEmpty ? '' : ' $unit'}';
  }
}

class _ParameterTile extends StatelessWidget {
  const _ParameterTile({
    required this.title,
    required this.value,
    required this.range,
    this.onEdit,
  });
  final String title;
  final String value;
  final String range;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(20),
      title: Text(title),
      subtitle: Text(range),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              key: const Key('edit-charge-limit'),
              tooltip: AppLocalizations.of(context).editParameter,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ],
      ),
    ),
  );
}
