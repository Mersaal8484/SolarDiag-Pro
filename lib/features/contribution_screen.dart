import 'package:flutter/material.dart';
import '../design/precision_ui.dart';
import '../app/theme.dart';
import '../contribution/redaction.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../l10n/generated/app_localizations.dart';

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});
  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  int step = 0;
  bool logs = true;
  bool notes = false;
  late final preview = const ContributionRedactor().redact(
    'model=OwnedDevice firmware=1.0 serial=SN123456 voltage=51.2',
    sessionSalt: 'preview',
  );
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 64),
      children: [
        PrecisionPageHeading(
          title: l10n.contributeSafely,
          subtitle: l10n.contributionPrivacy,
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 24),
        Stepper(
          currentStep: step,
          onStepTapped: (value) => setState(() => step = value),
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Row(
              children: [
                if (step < 3)
                  FilledButton(
                    onPressed: () => setState(() => step++),
                    child: Text(l10n.continueAction),
                  ),
                if (step > 0)
                  TextButton(
                    onPressed: () => setState(() => step--),
                    child: Text(l10n.backAction),
                  ),
              ],
            ),
          ),
          steps: [
            Step(
              title: Text(l10n.selectData),
              isActive: step >= 0,
              content: _Panel(
                icon: SolarIcons.library,
                title: l10n.ownedDeviceLog,
                detail: l10n.syntheticExcluded,
              ),
            ),
            Step(
              title: Text(l10n.redactionPreview),
              isActive: step >= 1,
              content: _Preview(preview: preview),
            ),
            Step(
              title: Text(l10n.consent),
              isActive: step >= 2,
              content: Column(
                children: [
                  CheckboxListTile(
                    value: logs,
                    onChanged: (value) => setState(() => logs = value ?? false),
                    title: Text(l10n.shareLogs),
                  ),
                  CheckboxListTile(
                    value: notes,
                    onChanged: (value) =>
                        setState(() => notes = value ?? false),
                    title: Text(l10n.shareNotes),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(l10n.submit),
              isActive: step >= 3,
              content: _Panel(
                icon: SolarIcons.offline,
                title: l10n.mockPortalOnly,
                detail: logs || notes ? l10n.packageReady : l10n.selectConsent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PrecisionCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                SolarIcon(
                  SolarIcons.librarySync,
                  color: Theme.of(
                    context,
                  ).extension<SolarTokens>()!.palette.tint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.libraryUpdates,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(l10n.noProductionChannel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.icon, required this.title, required this.detail});
  final SolarIconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        SolarIcon(
          icon,
          color: Theme.of(context).extension<SolarTokens>()!.palette.tint,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(detail),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.preview});
  final RedactionResult preview;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.labelPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            preview.redacted,
            style: TextStyle(
              color: palette.background.withValues(alpha: .72),
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context).redactedFields(preview.changes.length),
          style: TextStyle(fontWeight: FontWeight.w800, color: palette.tint),
        ),
      ],
    );
  }
}
