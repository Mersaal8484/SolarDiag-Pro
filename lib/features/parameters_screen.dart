import 'dart:async';

import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../app/theme.dart';
import '../auth/confirmation_factory.dart';
import '../design/accessibility.dart';
import '../design/components.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../l10n/generated/app_localizations.dart';
import '../parameters/parameter_models.dart';
import '../parameters/write_pipeline.dart';
import '../session/device_session.dart';
import 'library_write_reason_label.dart';

class ParametersScreen extends StatefulWidget {
  const ParametersScreen({super.key});

  @override
  State<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends State<ParametersScreen> {
  bool _requested = false;
  String? _selectedParameterId;

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
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final session = DeviceSessionScope.of(context);
    final entries = session.parameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final selectedId = entries.any((entry) => entry.key == _selectedParameterId)
        ? _selectedParameterId
        : entries.firstOrNull?.key;
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 64),
      children: [
        PrecisionPageHeading(
          title: s.parameters,
          subtitle: s.simulatorValuesNotice,
          icon: SolarIcons.configure,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.surfaceRaised, palette.surface],
            ),
            border: Border.all(color: palette.separator),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              SolarIcon(SolarIcons.simulated, color: palette.simulated),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.simulatedWritePipeline,
                  style: TextStyle(
                    color: palette.labelPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (session.libraryWriteDisabledReason case final reason?) ...[
          const SizedBox(height: 12),
          PrecisionCard(
            child: ListTile(
              leading: const SolarIcon(SolarIcons.locked),
              title: Text(s.physicalWriteLocked),
              subtitle: Text(localizedLibraryWriteReason(context, reason)),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (entries.isEmpty)
          Text(s.noParametersReported)
        else
          for (final entry in entries)
            _ParameterTile(
              id: entry.key,
              title: _label(s, entry.key),
              value: _value(context, entry.key, entry.value),
              range: _range(context, entry.key),
              selected: selectedId == entry.key,
              onSelect: () => setState(() => _selectedParameterId = entry.key),
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
              icon: const SolarIcon(SolarIcons.backup),
              label: Text(s.createBackup),
            ),
            OutlinedButton.icon(
              key: const Key('restore-latest-backup'),
              onPressed: session.backups.isEmpty
                  ? null
                  : () => _restoreBackup(session),
              icon: const SolarIcon(SolarIcons.restore),
              label: Text(s.restoreLatestBackup),
            ),
            OutlinedButton.icon(
              key: const Key('compare-latest-backup'),
              onPressed: session.backups.isEmpty
                  ? null
                  : () => _compareBackup(session),
              icon: const SolarIcon(SolarIcons.compare),
              label: Text(s.compareLatestBackup),
            ),
            FilledButton.icon(
              onPressed: null,
              icon: const SolarIcon(SolarIcons.locked),
              label: Text(s.physicalWriteLocked),
            ),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) return list;
        final selected = selectedId == null
            ? null
            : entries.firstWhere((entry) => entry.key == selectedId);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 2, child: list),
            SizedBox(
              width: 340,
              child: _ParameterInspector(
                title: selected == null
                    ? s.noParametersReported
                    : _label(s, selected.key),
                value: selected == null
                    ? s.notAvailable
                    : _value(context, selected.key, selected.value),
                range: selected == null
                    ? s.notAvailable
                    : _range(context, selected.key),
                writeStatus: session.libraryWriteDisabledReason == null
                    ? s.readOnly
                    : localizedLibraryWriteReason(
                        context,
                        session.libraryWriteDisabledReason!,
                      ),
              ),
            ),
          ],
        );
      },
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
      final unlocked = await _ensureUnlocked(session);
      if (!unlocked || !mounted) return;
    }
    final authorization = session.auth.current;
    if (authorization == null) return;
    final contextObj = session.createWriteContext();
    final tokens = plan.changes.map((change) {
      final before = session.parameters[change.definition.id] ?? 0;
      final diffHash = VerifiedWritePipeline.previewHash(
        change,
        before,
        contextObj,
      );
      return mintShownPlanConfirmation(
        shownPlanHash: diffHash,
        deviceId: contextObj.deviceId,
        sessionId: contextObj.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );
    }).toList();
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

  Future<bool> _ensureUnlocked(DeviceSession session) async {
    if (session.auth.isUnlocked) return true;
    final s = AppLocalizations.of(context);
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => _PinDialog(
        title: s.technicianAuthentication,
        label: s.technicianPin,
        hint: s.pinAuthorizationHint,
        cancelLabel: s.cancel,
        authenticateLabel: s.authenticateAction,
      ),
    );
    if (pin == null || pin.isEmpty) return false;
    return session.auth.unlock(
      tier: AuthorizationTier.technician,
      credentials: pin,
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
                leading: SolarIcon(
                  difference.changed
                      ? SolarIcons.diff
                      : SolarIcons.confirmedCheck,
                ),
                title: Text(_label(s, difference.parameterId)),
                subtitle: Text(
                  s.backupComparisonValues(
                    _optionalValue(
                      context,
                      s,
                      difference.parameterId,
                      difference.backupValue,
                    ),
                    _optionalValue(
                      context,
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

  static String _optionalValue(
    BuildContext context,
    AppLocalizations s,
    String id,
    num? value,
  ) => value == null ? s.notAvailable : _value(context, id, value);

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
                  '${_value(context, id, before)} → '
                  '${_value(context, id, requested)}',
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
                  label: _value(context, id, requested),
                  onChanged: (value) => setDialogState(
                    () => requested = (value * 10).round() / 10,
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
      final unlocked = await _ensureUnlocked(session);
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
    final token = mintShownPlanConfirmation(
      shownPlanHash: diffHash,
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
    final auditUnavailable = result.validation.issues.any(
      (issue) => issue.code == ValidationCode.auditKeyUnavailable,
    );
    final message = switch (result.outcome) {
      WriteOutcome.applied => s.writeAppliedWithReadback(
        _value(context, id, result.readback!),
      ),
      WriteOutcome.rejected =>
        auditUnavailable ? s.auditKeyUnavailable : s.writeRejected,
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

  static String _value(BuildContext context, String id, num value) {
    final definition = DeviceSession.parameterDefinitions[id];
    return localizedMeasurement(
      context,
      value,
      definition?.unit,
      fractionDigits: definition == null
          ? null
          : _fractionDigits(definition.step),
    );
  }

  static String _range(BuildContext context, String id) {
    final definition = DeviceSession.parameterDefinitions[id];
    if (definition == null) return id;
    final minimum = localizedMeasurement(
      context,
      definition.minimum,
      definition.unit,
      fractionDigits: _fractionDigits(definition.step),
    );
    final maximum = localizedMeasurement(
      context,
      definition.maximum,
      definition.unit,
      fractionDigits: _fractionDigits(definition.step),
    );
    final step = localizedMeasurement(
      context,
      definition.step,
      definition.unit,
      fractionDigits: _fractionDigits(definition.step),
    );
    return '$minimum–$maximum · $step';
  }

  static int _fractionDigits(num step) {
    final text = step.toString();
    if (!text.contains('.')) return 0;
    return text.split('.').last.replaceFirst(RegExp(r'0+$'), '').length;
  }
}

class _ParameterInspector extends StatelessWidget {
  const _ParameterInspector({
    required this.title,
    required this.value,
    required this.range,
    required this.writeStatus,
  });

  final String title;
  final String value;
  final String range;
  final String writeStatus;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 22, 20, 64),
    child: PrecisionCard(
      key: const Key('parameter-inspector'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                key: const ValueKey('parameter-inspector-semantics'),
                container: true,
                label:
                    '$title, $value, ${AppLocalizations.of(context).updatedNow}',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PrecisionSectionHeading(
                        label: AppLocalizations.of(context).parameters,
                        icon: SolarIcons.configure,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      TechnicalText(
                        value,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      TechnicalText(range),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              StatusPill(label: writeStatus, status: SolarStatus.info),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.cancelLabel,
    required this.authenticateLabel,
  });

  final String title;
  final String label;
  final String hint;
  final String cancelLabel;
  final String authenticateLabel;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late final TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text;
    _pinController.clear();
    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _pinController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
      ),
      autofocus: true,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.cancelLabel),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.authenticateLabel)),
    ],
  );
}

class _ParameterTile extends StatelessWidget {
  const _ParameterTile({
    required this.id,
    required this.title,
    required this.value,
    required this.range,
    required this.selected,
    required this.onSelect,
    this.onEdit,
  });
  final String id;
  final String title;
  final String value;
  final String range;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final freshness = AppLocalizations.of(context).updatedNow;
    return Semantics(
      key: ValueKey('parameter-semantics-$id'),
      container: true,
      selected: selected,
      button: true,
      label: '$title, $value, $freshness',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PrecisionCard(
            child: InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: onEdit == null ? palette.info : palette.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                range,
                                softWrap: true,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 2,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 17,
                            color: palette.tint,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        key: const Key('edit-charge-limit'),
                        tooltip: AppLocalizations.of(context).editParameter,
                        onPressed: onEdit,
                        icon: const SolarIcon(SolarIcons.configure),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
