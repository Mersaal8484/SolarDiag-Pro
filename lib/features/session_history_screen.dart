import 'dart:convert';

import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../persistence/local_database.dart';
import '../reports/engineering_report.dart';
import '../session/device_session.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final records = DeviceSessionScope.of(context).history;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
        children: [
          PrecisionPageHeading(
            title: s.diagnosticHistory,
            subtitle: s.historyDescription,
            icon: Icons.history_toggle_off_outlined,
          ),
          const SizedBox(height: 24),
          if (records.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.noSavedSessions),
              ),
            )
          else
            for (final record in records) ...[
              _SessionCard(record: record),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.record});

  final DiagnosticSessionRecord record;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final shortHash = record.dataHash.substring(0, 12);
    return Card(
      child: Column(
        children: [
          ListTile(
            key: ValueKey('history-${record.id}'),
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.history),
            title: Text(s.scenarioValue(record.scenario)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.lastUpdatedValue(record.updatedAt.toLocal().toString()),
                  ),
                  const SizedBox(height: 4),
                  Text(s.integrityHashValue(shortHash)),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDetails(context),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 18),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                key: ValueKey('export-${record.id}'),
                onPressed: () => _previewReport(context),
                icon: const Icon(Icons.preview_outlined),
                label: Text(s.previewReport),
              ),
            ),
          ),
        ],
      ),
    );
  }

  EngineeringReportData _reportData(DeviceSession session) =>
      EngineeringReportData(
        sessions: [record],
        parameters: session.parameters,
        alarms: session.alarmCodes,
        findings: [
          for (final finding in session.compatibilityAssessment.findings)
            {'severity': finding.state.name, 'message': finding.message},
        ],
      );

  Future<void> _previewReport(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final language = await showDialog<ReportLanguage>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.reportPreview),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.simulated)
                  Center(
                    child: Text(
                      s.simulated,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.scenarioValue(record.scenario)),
                  subtitle: Text(s.integrityHashValue(record.dataHash)),
                ),
                Text(s.reportContentsDescription),
                const SizedBox(height: 14),
                Text(s.reportLanguage),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in ReportLanguage.values)
                      OutlinedButton(
                        key: ValueKey('report-language-${item.name}'),
                        onPressed: () => Navigator.pop(dialogContext, item),
                        child: Text(_languageLabel(s, item)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
    if (language != null && context.mounted) {
      await _export(context, language);
    }
  }

  Future<void> _export(BuildContext context, ReportLanguage language) async {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await const EngineeringReportService().export(
        _reportData(session),
        language: language,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.reportExported(result.pdfPath, result.jsonPath)),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.reportExportFailed)));
    }
  }

  static String _languageLabel(AppLocalizations s, ReportLanguage language) =>
      switch (language) {
        ReportLanguage.english => s.english,
        ReportLanguage.arabic => s.arabic,
        ReportLanguage.bilingual => s.bilingual,
      };

  void _showDetails(BuildContext context) {
    final s = AppLocalizations.of(context);
    final events = DeviceSessionScope.of(context).eventsFor(record.id);
    final formatted = const JsonEncoder.withIndent(
      '  ',
    ).convert(jsonDecode(record.snapshotJson));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.sessionEvidence),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.sessionTimeline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (events.isEmpty)
                  Text(s.noTimelineEvents)
                else
                  for (final event in events)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle, size: 12),
                      title: Text(_eventLabel(s, event.type)),
                      subtitle: Text(
                        '${event.occurredAt.toLocal()} · ${event.payloadJson}',
                      ),
                    ),
                const Divider(),
                Text(
                  s.rawSessionEvidence,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(formatted),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.closeAction),
          ),
        ],
      ),
    );
  }

  static String _eventLabel(AppLocalizations s, String type) => switch (type) {
    'session_started' => s.sessionStarted,
    'link_state_changed' => s.linkStateChanged,
    'alarms_changed' => s.alarmsChanged,
    _ => s.sessionEvent,
  };
}
