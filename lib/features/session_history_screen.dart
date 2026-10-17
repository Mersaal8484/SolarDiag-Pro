import 'dart:convert';

import 'package:flutter/material.dart';

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
          Text(
            s.diagnosticHistory,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(s.historyDescription),
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
                onPressed: () => _export(context),
                icon: const Icon(Icons.file_download_outlined),
                label: Text(s.exportJsonPdf),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await const EngineeringReportService().export(
        EngineeringReportData(
          sessions: [record],
          parameters: session.parameters,
          alarms: session.alarmCodes,
          findings: [
            for (final finding in session.compatibilityAssessment.findings)
              {'severity': finding.state.name, 'message': finding.message},
          ],
        ),
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

  void _showDetails(BuildContext context) {
    final s = AppLocalizations.of(context);
    final formatted = const JsonEncoder.withIndent(
      '  ',
    ).convert(jsonDecode(record.snapshotJson));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.sessionEvidence),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(child: SelectableText(formatted)),
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
}
