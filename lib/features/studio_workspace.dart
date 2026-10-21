import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../studio/capture_analysis.dart';
import '../studio/capture_importers.dart';
import '../studio/capture_models.dart';
import '../studio/differential_analysis.dart';
import '../studio/findings.dart';
import '../studio/profile_builder.dart';
import '../studio/protocol_analysis.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/accessibility.dart';

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
  const StudioWorkspace({super.key});
  @override
  State<StudioWorkspace> createState() => _StudioWorkspaceState();
}

class _StudioWorkspaceState extends State<StudioWorkspace> {
  StudioSection section = StudioSection.sessions;
  late CaptureSession session = _syntheticSession();
  late CaptureAnalysis analysis = const CaptureAnalyzer().analyze(
    session,
  );
  late final CaptureSession comparisonSession = _comparisonSession();
  late ProtocolAnalysisReport protocolAnalysis =
      const ProtocolAnalysisEngine().analyze(session);
  late SafeDifferentialReport differential =
      const SafeDifferentialAnalyzer(
        maximumCandidates: 12,
      ).compare(session, comparisonSession, baselineRepeat: session);

  void _onSessionImported(CaptureSession newSession) {
    setState(() {
      session = newSession;
      analysis = const CaptureAnalyzer().analyze(session);
      protocolAnalysis = const ProtocolAnalysisEngine().analyze(session);
      differential = const SafeDifferentialAnalyzer(
        maximumCandidates: 12,
      ).compare(session, comparisonSession, baselineRepeat: session);
      section = StudioSection.frames;
    });
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
              duration: const Duration(milliseconds: 180),
              child: _section(context, section),
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
                      icon: Icon(_icon(item)),
                      label: _label(item),
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  Widget _section(BuildContext context, StudioSection value) => switch (value) {
    StudioSection.sessions => _StudioPage(
      key: const ValueKey('sessions'),
      eyebrow: 'RESEARCH SESSION',
      title: 'Synthetic CAN study',
      subtitle: 'One isolated session · no hardware attached',
      body: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _Stat(label: 'Frames', value: '${session.frames.length}'),
          _Stat(label: 'Identifiers', value: '${analysis.identifiers.length}'),
          const _Stat(label: 'Source', value: 'SYNTHETIC'),
          const _Stat(label: 'TX', value: 'LOCKED'),
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
      title: '${session.frames.length} timestamped frames',
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
      title: '${differential.candidates.length} ranked candidates',
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
          _FindingView(finding: finding),
          for (final item in protocolAnalysis.findings) ...[
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
  Widget build(BuildContext context) => Material(
    color: SolarColors.deep,
    child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Text(
            AppLocalizations.of(context).studioEngineering,
            style: const TextStyle(
              color: SolarColors.lime,
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
              selectedTileColor: SolarColors.lime,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Icon(
                _icon(item),
                color: selected == item
                    ? SolarColors.deep
                    : SolarColors.onDarkMuted,
              ),
              title: Text(
                _label(item),
                style: TextStyle(
                  color: selected == item
                      ? SolarColors.deep
                      : SolarColors.onDarkStrong,
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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: SolarColors.green,
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
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 28),
      body,
    ],
  );
}

class _ReplayLockBadge extends StatelessWidget {
  const _ReplayLockBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: SolarColors.lime,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline, size: 15, color: SolarColors.deep),
        const SizedBox(width: 6),
        Text(
          AppLocalizations.of(context).replayLock,
          style: const TextStyle(
            color: SolarColors.deep,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 120,
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
  );
}

class _EmptyInstrument extends StatelessWidget {
  const _EmptyInstrument({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 42, color: SolarColors.green),
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
        icon: Icons.sensors_off_outlined,
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
                icon: const Icon(Icons.file_upload_outlined),
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
                      if (val != null) setDialogState(() => selectedFormat = val);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                } else {
                  Navigator.pop(dialogContext);
                  onSessionImported?.call(result.session!);
                  final message =
                      'Loaded ${result.session!.frames.length} frames successfully.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
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
              _MiniMetric(label: 'Pairs', value: '${report.pairs.length}'),
              _MiniMetric(
                label: 'Polling',
                value: '${report.pollingPatterns.length}',
              ),
              _MiniMetric(
                label: 'Modbus frames',
                value: '${report.modbusFrames.length}',
              ),
              _MiniMetric(
                label: 'Findings',
                value: '${report.findings.length}',
              ),
              _MiniMetric(
                label: 'Clusters',
                value: '${report.clusters.length}',
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
        icon: Icons.difference_outlined,
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
                child: TechnicalText('${(candidate.score * 100).round()}'),
              ),
              title: TechnicalText(
                '0x${candidate.identifier.toRadixString(16).toUpperCase()} · byte ${candidate.byteOffset}${candidate.bitIndex == null ? '' : ' · bit ${candidate.bitIndex}'}',
              ),
              subtitle: Text(_differentialSummary(candidate)),
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
                    'ID',
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
              separatorBuilder: (_, __) => const Divider(height: 1),
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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: const Icon(Icons.memory),
      title: TechnicalText(
        '0x${stats.identifier.toRadixString(16).toUpperCase()}',
      ),
      subtitle: TechnicalText(
        '${stats.frameCount} frames · ${stats.averagePeriodMicros?.toStringAsFixed(0) ?? '—'} µs period',
      ),
      trailing: TechnicalText(
        'Δ [${stats.changedByteOffsets.join(', ')}]',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
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
              leading: const Icon(Icons.link),
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
          Text(
            '${draft.mappings.length} evidenced mapping · ${draft.referenceIds.length} reference',
          ),
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
      leading: const Icon(Icons.account_tree_outlined),
      title: Text(mapping.field),
      subtitle: Text(
        '0x${mapping.frameIdentifier.toRadixString(16)} · offset ${mapping.offset} · ${mapping.dataType.name} · ×${mapping.scale} ${mapping.unit}',
      ),
      trailing: const Icon(Icons.verified_outlined, color: SolarColors.green),
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
          Icon(
            result.isValid ? Icons.check_circle : Icons.error_outline,
            color: result.isValid
                ? SolarColors.green
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
          color: SolarColors.deep,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SelectableText(
          json,
          style: const TextStyle(
            color: SolarColors.onDarkStrong,
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
IconData _icon(StudioSection section) => switch (section) {
  StudioSection.sessions => Icons.folder_open_outlined,
  StudioSection.capture => Icons.sensors_outlined,
  StudioSection.frames => Icons.table_rows_outlined,
  StudioSection.analysis => Icons.analytics_outlined,
  StudioSection.differential => Icons.difference_outlined,
  StudioSection.hypotheses => Icons.lightbulb_outline,
  StudioSection.profileBuilder => Icons.build_outlined,
  StudioSection.mapping => Icons.account_tree_outlined,
  StudioSection.validation => Icons.fact_check_outlined,
  StudioSection.export => Icons.ios_share_outlined,
};

abstract final class _StudioCopy {
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

String _differentialSummary(DifferentialFieldCandidate candidate) =>
    'A ${candidate.baselineValues.join('/')} → '
    'B ${candidate.comparisonValues.join('/')} · '
    '${candidate.evidence.length} frame references';
