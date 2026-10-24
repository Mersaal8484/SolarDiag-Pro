import 'dart:async';

import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../app/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../parameters/parameter_models.dart';
import '../parameters/write_pipeline.dart';
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
        PrecisionPageHeading(
          title: s.parameters,
          subtitle: s.simulatorValuesNotice,
          icon: Icons.tune_outlined,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF193758), Color(0xFF0B1B34)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF344E70)),
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
            OutlinedButton.icon(
              key: const Key('compare-latest-backup'),
              onPressed: session.backups.isEmpty
                  ? null
                  : () => _compareBackup(session),
              icon: const Icon(Icons.compare_arrows),
              label: Text(s.compareLatestBackup),
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
    final plan = session.planRestore(backup);
    if (plan.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.backupAlreadyMatches)));
      return;
    }
    var acknowledged = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(s.restoreBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.restoreBackupConfirmation(plan.length)),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: acknowledged,
                title: Text(s.safetyAcknowledgement),
                onChanged: (val) =>
                    setDialogState(() => acknowledged = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              key: const Key('confirm-backup-restore'),
              onPressed: acknowledged
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(s.confirmRestore),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!session.auth.isUnlocked) {
      final unlocked = await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'technician-authenticated',
      );
      if (!unlocked || !mounted) return;
    }
    final authorization = session.auth.current;
    if (authorization == null) return;
    final contextObj = session.createWriteContext();
    final tokens = <ConfirmationToken>[];
    for (final change in plan.changes) {
      final before = session.parameters[change.definition.id] ?? 0;
      final diffHash = VerifiedWritePipeline.previewHash(
        change,
        before,
        contextObj,
      );
      tokens.add(
        ConfirmationToken(
          diffHash: diffHash,
          deviceId: contextObj.deviceId,
          sessionId: contextObj.sessionId,
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        ),
      );
    }
    final results = await session.restoreParameterBackup(
      plan: plan,
      authorization: authorization,
      confirmations: tokens,
      safetyAcknowledged: acknowledged,
    );
    if (!mounted) return;
    final applied = results.where(
      (result) => result.outcome == WriteOutcome.applied,
    );
    final success = applied.length == plan.length;
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

  Future<void> _compareBackup(DeviceSession session) async {
    final s = AppLocalizations.of(context);
    final differences = session.backups.first.compare(session.parameters);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.backupComparison),
        content: SizedBox(
          width: 560,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: differences.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final difference = differences[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  difference.changed
                      ? Icons.change_circle_outlined
                      : Icons.check_circle_outline,
                ),
                title: Text(_label(s, difference.parameterId)),
                subtitle: Text(
                  s.backupComparisonValues(
                    _optionalValue(
                      s,
                      difference.parameterId,
                      difference.backupValue,
                    ),
                    _optionalValue(
                      s,
                      difference.parameterId,
                      difference.currentValue,
                    ),
                  ),
                ),
                trailing: Text(difference.changed ? s.changed : s.unchanged),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.closeAction),
          ),
        ],
      ),
    );
  }

  static String _optionalValue(AppLocalizations s, String id, num? value) =>
      value == null ? s.notAvailable : _value(id, value);

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
    if (!session.auth.isUnlocked) {
      final unlocked = await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'technician-authenticated',
      );
      if (!unlocked || !mounted) return;
    }
    final authorization = session.auth.current;
    if (authorization == null) return;
    final contextObj = session.createWriteContext();
    final change = ParameterChange(
      definition: definition,
      requestedValue: confirmed,
    );
    final diffHash = VerifiedWritePipeline.previewHash(
      change,
      before,
      contextObj,
    );
    final token = ConfirmationToken(
      diffHash: diffHash,
      deviceId: contextObj.deviceId,
      sessionId: contextObj.sessionId,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
    final result = await session.applySimulatedParameterChange(
      parameterId: id,
      requestedValue: confirmed,
      authorization: authorization,
      confirmation: token,
      safetyAcknowledged: acknowledged,
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
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: onEdit == null
              ? SolarColors.green.withValues(alpha: .10)
              : SolarColors.amber.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          onEdit == null ? Icons.lock_outline : Icons.tune,
          color: onEdit == null ? SolarColors.green : SolarColors.amber,
        ),
      ),
      title: Text(title),
      subtitle: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(range),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
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
