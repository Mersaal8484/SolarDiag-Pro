import 'dart:async';

import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../persistence/local_database.dart';
import '../studio/capture_analysis.dart';
import '../studio/capture_importers.dart';
import '../studio/capture_models.dart';
import '../studio/differential_analysis.dart';
import '../studio/findings.dart';
import '../studio/profile_builder.dart';
import '../studio/protocol_analysis.dart';
import '../studio/research_repository.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/accessibility.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../design/tokens.g.dart';

enum StudioSection {
  sessions,
  capture,
  frames,
  analysis,
  differential,
  hypotheses,
  profileBuilder,
  mapping,
  validation,
  export,
}

class StudioWorkspace extends StatefulWidget {
  const StudioWorkspace({super.key, this.database});
  final LocalDatabase? database;

  @override
  State<StudioWorkspace> createState() => _StudioWorkspaceState();
}

class _StudioWorkspaceState extends State<StudioWorkspace> {
  late final LocalResearchRepository? _repository = widget.database == null
      ? null
      : LocalResearchRepository(widget.database!);
  StudioSection section = StudioSection.sessions;
  late CaptureSession session = _syntheticSession();
  late CaptureAnalysis analysis = const CaptureAnalyzer().analyze(session);
  late final CaptureSession comparisonSession = _comparisonSession();
  late ProtocolAnalysisReport protocolAnalysis = const ProtocolAnalysisEngine()
      .analyze(session);
  late SafeDifferentialReport differential = const SafeDifferentialAnalyzer(
    maximumCandidates: 12,
  ).compare(session, comparisonSession, baselineRepeat: session);
  List<CaptureSession> _savedSessions = const [];
  List<ProtocolFinding> _savedFindings = const [];
  bool _persistenceError = false;

  @override
  void initState() {
    super.initState();
    if (widget.database == null) {
      _persistenceError = true;
    } else {
      unawaited(_restoreResearch());
    }
  }

  Future<void> _restoreResearch() async {
    final repository = _repository;
    if (repository == null) {
      setState(() => _persistenceError = true);
      return;
    }
    try {
      final savedSessions = await repository.sessions();
      final savedFindings = await repository.findings();
      if (!mounted) return;
      setState(() {
        _savedSessions = savedSessions;
        _savedFindings = savedFindings;
        if (savedSessions.isNotEmpty) {
          _applySession(savedSessions.first);
        }
      });
    } catch (error, stackTrace) {
      _reportPersistenceError(error, stackTrace);
    }
  }

  void _onSessionImported(CaptureSession newSession) {
    setState(() {
      _applySession(newSession);
      section = StudioSection.frames;
    });
    unawaited(_persistResearch(newSession));
  }

  void _applySession(CaptureSession value) {
    session = value;
    analysis = const CaptureAnalyzer().analyze(session);
    protocolAnalysis = const ProtocolAnalysisEngine().analyze(session);
    differential = const SafeDifferentialAnalyzer(
      maximumCandidates: 12,
    ).compare(session, comparisonSession, baselineRepeat: session);
  }

  Future<void> _persistResearch(CaptureSession importedSession) async {
    final repository = _repository;
    if (repository == null) {
      setState(() => _persistenceError = true);
      return;
    }
    final findings = List<ProtocolFinding>.of(protocolAnalysis.findings);
    try {
      await repository.saveSession(importedSession);
      for (final item in findings) {
        await repository.saveFinding(item);
      }
      final savedSessions = await repository.sessions();
      final savedFindings = await repository.findings();
      if (!mounted) return;
      setState(() {
        _savedSessions = savedSessions;
        _savedFindings = savedFindings;
      });
    } catch (error, stackTrace) {
      _reportPersistenceError(error, stackTrace);
    }
  }

  void _reportPersistenceError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'protocol studio persistence',
      ),
    );
    if (mounted) setState(() => _persistenceError = true);
  }

  List<ProtocolFinding> get _findingsForDisplay {
    final findings = <String, ProtocolFinding>{};
    for (final item in _savedFindings) {
      if (item.evidence.any(
        (evidence) =>
            evidence.captureId == session.id ||
            evidence.reference.startsWith('${session.id}:'),
      )) {
        findings[item.id] = item;
      }
    }
    for (final item in protocolAnalysis.findings) {
      findings[item.id] = item;
    }
    return findings.values.toList(growable: false);
  }

  late final StudioProfileDraft draft = StudioProfileDraft(
    id: 'studio.synthetic.can.v1',
    manufacturer: 'SolarDiag Research',
    family: 'Synthetic CAN',
    referenceIds: const ['solardiag-simulator-spec-001'],
    mappings: const [
      FieldMapping(
        field: 'state_of_charge',
        frameIdentifier: 0x355,
        offset: 0,
        length: 2,
        dataType: FieldDataType.unsigned16,
        scale: .1,
        unit: '%',
        evidenceReferences: ['synthetic-001:frames:4-6'],
      ),
    ],
  );
  late final ProtocolFinding finding = ProtocolFinding.observation(
    id: 'finding-soc',
    title: 'Bytes 0–1 may encode state of charge',
    evidence: [
      const FindingEvidence(
        kind: EvidenceKind.captureFrame,
        reference: 'synthetic-001:4',
        summary: 'Value changes with scripted SOC',
        captureId: 'synthetic-001',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).protocolStudio),
        actions: [const _ReplayLockBadge(), const SizedBox(width: 14)],
      ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 238,
              child: _SectionList(
                selected: section,
                onSelected: (value) => setState(() => section = value),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : SolarMotion.fast,
              child: KeyedSubtree(
                key: ValueKey(section),
                child: Column(
                  children: [
                    if (_persistenceError)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          AppLocalizations.of(context).studioPersistenceError,
                        ),
                      ),
                    Expanded(child: _section(context, section)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !wide
          ? NavigationBar(
              selectedIndex: section.index.clamp(0, 4),
              onDestinationSelected: (value) =>
                  setState(() => section = StudioSection.values[value]),
              destinations: StudioSection.values
                  .take(5)
                  .map(
                    (item) => NavigationDestination(
                      icon: SolarIcon(_icon(item)),
                      label: _label(item),
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  String _formatCount(BuildContext context, int count) =>
      localizedNumber(context, count, fractionDigits: 0);

  Widget _section(BuildContext context, StudioSection value) => switch (value) {
    StudioSection.sessions => _StudioPage(
      key: const ValueKey('sessions'),
      eyebrow: 'RESEARCH SESSION',
      title: session.synthetic
          ? 'Synthetic CAN study'
          : 'Imported capture ${session.id}',
      subtitle: session.synthetic
          ? 'One isolated session · no hardware attached'
          : 'Imported read-only capture · no hardware attached',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Stat(
                label: 'Frames',
                value: _formatCount(context, session.frames.length),
              ),
              _Stat(
                label: 'Identifiers',
                value: _formatCount(context, analysis.identifiers.length),
              ),
              _Stat(
                label: 'Source',
                value: session.synthetic ? 'SYNTHETIC' : session.source.name,
              ),
              const _Stat(label: 'TX', value: 'LOCKED'),
            ],
          ),
          for (final savedSession in _savedSessions)
            ListTile(
              title: Text(savedSession.id),
              subtitle: Text(
                '${_formatCount(context, savedSession.frames.length)} frames',
              ),
              onTap: () => setState(() => _applySession(savedSession)),
            ),
        ],
      ),
    ),
    StudioSection.capture => _StudioPage(
      key: const ValueKey('capture'),
      eyebrow: 'PASSIVE CAPTURE',
      title: 'Capture controls',
      subtitle: 'Hardware capture is unavailable in this build.',
      body: _CaptureSourcesView(onSessionImported: _onSessionImported),
    ),
    StudioSection.frames => _StudioPage(
      key: const ValueKey('frames'),
      eyebrow: 'FRAME EXPLORER',
      title:
          '${_formatCount(context, session.frames.length)} timestamped frames',
      subtitle: 'Raw values remain raw until evidence supports a mapping.',
      body: _FrameTable(frames: session.frames),
    ),
    StudioSection.analysis => _StudioPage(
      key: const ValueKey('analysis'),
      eyebrow: 'SIGNAL ANALYSIS',
      title: 'Identifiers & cadence',
      subtitle: 'Frequency, payload length and changing byte positions.',
      body: Column(
        children: [
          _ProtocolSummary(report: protocolAnalysis),
          const SizedBox(height: 14),
          ...analysis.identifiers.values.map(
            (stats) => _AnalysisRow(stats: stats),
          ),
        ],
      ),
    ),
    StudioSection.differential => _StudioPage(
      key: const ValueKey('diff'),
      eyebrow: 'DIFFERENTIAL',
      title:
          '${_formatCount(context, differential.candidates.length)} '
          'ranked candidates',
      subtitle: 'Synthetic A/B/A comparison · observations only',
      body: _DifferentialView(report: differential),
    ),
    StudioSection.hypotheses => _StudioPage(
      key: const ValueKey('hypotheses'),
      eyebrow: 'FINDINGS',
      title: 'Evidence, not guesses',
      subtitle: 'Every claim carries state, confidence and references.',
      body: Column(
        children: [
          if (session.synthetic) _FindingView(finding: finding),
          for (final item in _findingsForDisplay) ...[
            const SizedBox(height: 12),
            _FindingView(finding: item),
          ],
        ],
      ),
    ),
    StudioSection.profileBuilder => _StudioPage(
      key: const ValueKey('builder'),
      eyebrow: 'PROFILE BUILDER',
      title: draft.id,
      subtitle: 'Engineering-only draft · read-only',
      body: _IdentityCard(draft: draft),
    ),
    StudioSection.mapping => _StudioPage(
      key: const ValueKey('mapping'),
      eyebrow: 'PARAMETER MAPPING',
      title: 'Telemetry map',
      subtitle: 'Offsets and scaling remain tied to capture evidence.',
      body: Column(
        children: draft.mappings
            .map((mapping) => _MappingRow(mapping: mapping))
            .toList(),
      ),
    ),
    StudioSection.validation => _StudioPage(
      key: const ValueKey('validation'),
      eyebrow: 'OFFLINE VALIDATION',
      title: 'Draft checks',
      subtitle: 'No real bus is involved.',
      body: _ValidationView(result: const ProfileBuilder().validate(draft)),
    ),
    StudioSection.export => _StudioPage(
      key: const ValueKey('export'),
      eyebrow: 'EXPORT',
      title: 'Studio draft only',
      subtitle: 'Never loadable in technician mode.',
      body: _ExportView(json: const ProfileBuilder().exportStudioDraft(draft)),
    ),
  };
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.selected, required this.onSelected});
  final StudioSection selected;
  final ValueChanged<StudioSection> onSelected;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Material(
      color: palette.labelPrimary,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            child: Text(
              AppLocalizations.of(context).studioEngineering,
              style: TextStyle(
                color: palette.simulated,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final item in StudioSection.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                selected: selected == item,
                selectedTileColor: palette.simulated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: SolarIcon(
                  _icon(item),
                  color: selected == item
                      ? palette.labelPrimary
                      : palette.background.withValues(alpha: .62),
                ),
                title: Text(
                  _label(item),
                  style: TextStyle(
                    color: selected == item
                        ? palette.labelPrimary
                        : palette.background.withValues(alpha: .72),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                onTap: () => onSelected(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudioPage extends StatelessWidget {
  const _StudioPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget body;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: palette.tint,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        body,
      ],
    );
  }
}

class _ReplayLockBadge extends StatelessWidget {
  const _ReplayLockBadge();
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.simulated,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          SolarIcon(
            SolarIcons.replayLock,
            size: 15,
            color: palette.labelPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).replayLock,
            style: TextStyle(
              color: palette.labelPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 120),
    child: SizedBox(
      width: 180,
      child: IntrinsicHeight(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmptyInstrument extends StatelessWidget {
  const _EmptyInstrument({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final SolarIconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          SolarIcon(
            icon,
            size: 42,
            color: Theme.of(context).extension<SolarTokens>()!.palette.tint,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _CaptureSourcesView extends StatelessWidget {
  const _CaptureSourcesView({this.onSessionImported});

  final ValueChanged<CaptureSession>? onSessionImported;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _EmptyInstrument(
        icon: SolarIcons.offline,
        title: 'No gateway connected',
        detail:
            'Import or generate synthetic data. Captured frames can never be replayed to hardware.',
      ),
      const SizedBox(height: 14),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _StudioCopy.importFormats,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_StudioCopy.sdcap)),
                  Chip(label: Text(_StudioCopy.candump)),
                  Chip(label: Text(_StudioCopy.csvMapping)),
                  Chip(label: Text(_StudioCopy.genericHex)),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSessionImported == null
                    ? null
                    : () => _showImportDialog(context),
                icon: const SolarIcon(SolarIcons.export),
                label: const Text(_StudioCopy.importCapture),
              ),
              const SizedBox(height: 16),
              Text(
                _StudioCopy.unsupportedFormats,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();
    var selectedFormat = 'candump';
    var isNda = false;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(_StudioCopy.importDialogTitle),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(_StudioCopy.selectFormat),
                  DropdownButton<String>(
                    value: selectedFormat,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'candump',
                        child: Text(_StudioCopy.candumpOption),
                      ),
                      DropdownMenuItem(
                        value: 'sdcap',
                        child: Text(_StudioCopy.sdcapOption),
                      ),
                      DropdownMenuItem(
                        value: 'generic',
                        child: Text(_StudioCopy.genericHexOption),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedFormat = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste capture file contents here...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(_StudioCopy.containsNda),
                    subtitle: const Text(_StudioCopy.ndaSubtitle),
                    value: isNda,
                    onChanged: (val) => setDialogState(() => isNda = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(_StudioCopy.cancel),
            ),
            FilledButton(
              onPressed: () {
                final source = textController.text.trim();
                if (source.isEmpty) return;
                final importer = switch (selectedFormat) {
                  'sdcap' => const SdcapImporter(),
                  'candump' => const CandumpImporter(),
                  _ => const GenericHexImporter(GenericHexRules()),
                };
                final importContext = CaptureImportContext(
                  sessionId: 'import-${DateTime.now().millisecondsSinceEpoch}',
                  startedAt: DateTime.now().toUtc(),
                  synthetic: false,
                  containsNdaMaterial: isNda,
                  notes: 'Imported via Studio',
                );
                final result = importer.import(source, importContext);
                if (result.hasErrors || result.session == null) {
                  final message =
                      'Import error: ${result.issues.firstOrNull?.message ?? "Failed to parse"}';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                } else {
                  Navigator.pop(dialogContext);
                  onSessionImported?.call(result.session!);
                  final frameCount = localizedNumber(
                    context,
                    result.session!.frames.length,
                  );
                  final message = 'Loaded $frameCount frames successfully.';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: const Text(_StudioCopy.importAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtocolSummary extends StatelessWidget {
  const _ProtocolSummary({required this.report});

  final ProtocolAnalysisReport report;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _StudioCopy.protocolEvidence,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniMetric(
                label: 'Pairs',
                value: localizedNumber(context, report.pairs.length),
              ),
              _MiniMetric(
                label: 'Polling',
                value: localizedNumber(context, report.pollingPatterns.length),
              ),
              _MiniMetric(
                label: 'Modbus frames',
                value: localizedNumber(context, report.modbusFrames.length),
              ),
              _MiniMetric(
                label: 'Findings',
                value: localizedNumber(context, report.findings.length),
              ),
              _MiniMetric(
                label: 'Clusters',
                value: localizedNumber(context, report.clusters.length),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          TechnicalText(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}

class _DifferentialView extends StatelessWidget {
  const _DifferentialView({required this.report});

  final SafeDifferentialReport report;

  @override
  Widget build(BuildContext context) {
    if (report.candidates.isEmpty) {
      return const _EmptyInstrument(
        icon: SolarIcons.diff,
        title: 'No differential candidates',
        detail: 'The controlled captures have equivalent field distributions.',
      );
    }
    return Column(
      children: [
        for (final candidate in report.candidates)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                child: TechnicalText(
                  localizedNumber(context, (candidate.score * 100).round()),
                ),
              ),
              title: TechnicalText(_differentialLocation(context, candidate)),
              subtitle: Text(_differentialSummary(context, candidate)),
              trailing: candidate.repeatedAba
                  ? const Chip(label: Text(_StudioCopy.aba))
                  : const Chip(label: Text(_StudioCopy.ab)),
            ),
          ),
      ],
    );
  }
}

class _FrameTable extends StatelessWidget {
  const _FrameTable({required this.frames});
  final List<CaptureFrame> frames;

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text(_StudioCopy.noFrames)),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticky header
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    AppLocalizations.of(context).timeMicroseconds,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: TechnicalText(
                    _StudioCopy.identifier,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    AppLocalizations.of(context).direction,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    AppLocalizations.of(context).payload,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Virtualized list builder - only renders visible rows, enabling large captures
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: frames.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final frame = frames[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TechnicalText('${frame.timestampMicros}'),
                      ),
                      Expanded(
                        flex: 2,
                        child: TechnicalText(
                          frame.identifier == null
                              ? frame.protocolHint ?? frame.channel
                              : '0x${frame.identifier!.toRadixString(16).toUpperCase()}',
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(frame.received ? 'RX' : 'TX'),
                      ),
                      Expanded(
                        flex: 4,
                        child: TechnicalText(
                          frame.payload
                              .map(
                                (byte) =>
                                    byte.toRadixString(16).padLeft(2, '0'),
                              )
                              .join(' ')
                              .toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow({required this.stats});
  final IdentifierStatistics stats;
  @override
  Widget build(BuildContext context) {
    final frameCount = localizedNumber(
      context,
      stats.frameCount,
      fractionDigits: 0,
    );
    final averagePeriod = stats.averagePeriodMicros == null
        ? '—'
        : localizedNumber(context, stats.averagePeriodMicros!);
    final changedOffsets = stats.changedByteOffsets
        .map((offset) => localizedNumber(context, offset, fractionDigits: 0))
        .join(', ');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: const SolarIcon(SolarIcons.frame),
        title: TechnicalText(
          '0x${stats.identifier.toRadixString(16).toUpperCase()}',
        ),
        subtitle: TechnicalText(
          '$frameCount frames · $averagePeriod µs period',
        ),
        trailing: TechnicalText(
          'Δ [$changedOffsets]',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _FindingView extends StatelessWidget {
  const _FindingView({required this.finding});
  final ProtocolFinding finding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(label: Text(finding.state.name.toUpperCase())),
              const Spacer(),
              Text(
                AppLocalizations.of(
                  context,
                ).confidencePercent((finding.confidence * 100).round()),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(finding.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          for (final evidence in finding.evidence)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const SolarIcon(SolarIcons.linkDiagnostics),
              title: Text(evidence.reference),
              subtitle: Text(evidence.summary),
            ),
        ],
      ),
    ),
  );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.draft});
  final StudioProfileDraft draft;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(label: Text(AppLocalizations.of(context).studioDraft)),
          const SizedBox(height: 12),
          Text(
            '${draft.manufacturer} / ${draft.family}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_mappingCountLabel(context, draft)),
        ],
      ),
    ),
  );
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({required this.mapping});
  final FieldMapping mapping;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: const SolarIcon(SolarIcons.registerMap),
      title: Text(mapping.field),
      subtitle: Text(
        '0x${mapping.frameIdentifier.toRadixString(16)} · '
        'offset ${localizedNumber(context, mapping.offset)} · '
        '${mapping.dataType.name} · ×${mapping.scale} ${mapping.unit}',
      ),
      trailing: SolarIcon(
        SolarIcons.verifiedDocument,
        color: Theme.of(context).extension<SolarTokens>()!.palette.tint,
      ),
    ),
  );
}

class _ValidationView extends StatelessWidget {
  const _ValidationView({required this.result});
  final DraftValidationResult result;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          SolarIcon(
            result.isValid ? SolarIcons.confirmedCheck : SolarIcons.critical,
            color: result.isValid
                ? Theme.of(context).extension<SolarTokens>()!.palette.ok
                : Theme.of(context).colorScheme.error,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              result.isValid
                  ? 'Offline schema and evidence checks passed.'
                  : result.issues.map((item) => item.message).join('\n'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExportView extends StatelessWidget {
  const _ExportView({required this.json});
  final String json;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).extension<SolarTokens>()!.palette.labelPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SelectableText(
          json,
          style: TextStyle(
            color: Theme.of(context)
                .extension<SolarTokens>()!
                .palette
                .background
                .withValues(alpha: .72),
            fontFamily: 'monospace',
            height: 1.45,
          ),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: null,
        child: Text(AppLocalizations.of(context).technicianPublicationDisabled),
      ),
    ],
  );
}

CaptureSession _syntheticSession() => CaptureSession(
  id: 'synthetic-001',
  interfaceType: CaptureInterface.can,
  source: CaptureSource.synthetic,
  startedAt: DateTime.utc(2026),
  synthetic: true,
  containsNdaMaterial: false,
  notes: 'Studio demo',
  frames: const [
    CaptureFrame(
      timestampMicros: 0,
      identifier: 0x351,
      payload: [0x02, 0x28, 0x01],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 100000,
      identifier: 0x351,
      payload: [0x02, 0x28, 0x02],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 200000,
      identifier: 0x351,
      payload: [0x02, 0x28, 0x03],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 25000,
      identifier: 0x355,
      payload: [0x03, 0x0C],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 125000,
      identifier: 0x355,
      payload: [0x03, 0x0B],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 225000,
      identifier: 0x355,
      payload: [0x03, 0x0A],
      received: true,
    ),
  ],
);

CaptureSession _comparisonSession() => CaptureSession(
  id: 'synthetic-002',
  interfaceType: CaptureInterface.can,
  source: CaptureSource.synthetic,
  startedAt: DateTime.utc(2026, 1, 2),
  synthetic: true,
  containsNdaMaterial: false,
  notes: 'Controlled synthetic comparison',
  frames: const [
    CaptureFrame(
      timestampMicros: 0,
      identifier: 0x351,
      payload: [0x02, 0x30, 0x01],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 100000,
      identifier: 0x351,
      payload: [0x02, 0x30, 0x02],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 200000,
      identifier: 0x351,
      payload: [0x02, 0x30, 0x03],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 25000,
      identifier: 0x355,
      payload: [0x03, 0x14],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 125000,
      identifier: 0x355,
      payload: [0x03, 0x13],
      received: true,
    ),
    CaptureFrame(
      timestampMicros: 225000,
      identifier: 0x355,
      payload: [0x03, 0x12],
      received: true,
    ),
  ],
);

String _label(StudioSection section) => switch (section) {
  StudioSection.sessions => 'Sessions',
  StudioSection.capture => 'Capture',
  StudioSection.frames => 'Frame explorer',
  StudioSection.analysis => 'Analysis',
  StudioSection.differential => 'Differential',
  StudioSection.hypotheses => 'Hypotheses',
  StudioSection.profileBuilder => 'Profile builder',
  StudioSection.mapping => 'Mapping editor',
  StudioSection.validation => 'Validation',
  StudioSection.export => 'Export',
};
SolarIconData _icon(StudioSection section) => switch (section) {
  StudioSection.sessions => SolarIcons.library,
  StudioSection.capture => SolarIcons.captureRecord,
  StudioSection.frames => SolarIcons.frame,
  StudioSection.analysis => SolarIcons.evidence,
  StudioSection.differential => SolarIcons.diff,
  StudioSection.hypotheses => SolarIcons.hypothesis,
  StudioSection.profileBuilder => SolarIcons.profileBuilder,
  StudioSection.mapping => SolarIcons.registerMap,
  StudioSection.validation => SolarIcons.confirmedCheck,
  StudioSection.export => SolarIcons.export,
};

abstract final class _StudioCopy {
  static const identifier = 'ID';
  static const importFormats = 'Import formats';
  static const sdcap = '.sdcap v1/v2';
  static const candump = 'candump';
  static const csvMapping = 'CSV mapping';
  static const genericHex = 'Generic HEX';
  static const unsupportedFormats =
      'Not implemented: SLCAN, PCAP/PCAPNG Modbus TCP, Vector ASC';
  static const protocolEvidence = 'Protocol evidence';
  static const aba = 'A/B/A';
  static const ab = 'A/B';
  static const importCapture = 'Import Capture Data';
  static const importDialogTitle = 'Import Capture';
  static const selectFormat = 'Select format:';
  static const candumpOption = 'Linux candump (.log)';
  static const sdcapOption = 'SolarDiag Capture (.sdcap)';
  static const genericHexOption = 'Generic HEX text';
  static const containsNda = 'Contains NDA material';
  static const ndaSubtitle = 'Blocks export and contribution';
  static const cancel = 'Cancel';
  static const importAction = 'Import';
  static const noFrames = 'No frames recorded in this session.';
}

String _differentialSummary(
  BuildContext context,
  DifferentialFieldCandidate candidate,
) =>
    'A ${candidate.baselineValues.join('/')} → '
    'B ${candidate.comparisonValues.join('/')} · '
    '${localizedNumber(context, candidate.evidence.length)} frame references';

String _differentialLocation(
  BuildContext context,
  DifferentialFieldCandidate candidate,
) {
  final identifier = candidate.identifier.toRadixString(16).toUpperCase();
  final byteOffset = localizedNumber(
    context,
    candidate.byteOffset,
    fractionDigits: 0,
  );
  final bitIndex = candidate.bitIndex;
  final bit = bitIndex == null
      ? ''
      : ' · bit ${localizedNumber(context, bitIndex, fractionDigits: 0)}';
  return '0x$identifier · byte $byteOffset$bit';
}

String _mappingCountLabel(BuildContext context, StudioProfileDraft draft) {
  final mappingCount = localizedNumber(
    context,
    draft.mappings.length,
    fractionDigits: 0,
  );
  final referenceCount = localizedNumber(
    context,
    draft.referenceIds.length,
    fractionDigits: 0,
  );
  return '$mappingCount evidenced mapping · $referenceCount reference';
}
