import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../contribution/redaction.dart';

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
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Contribute safely',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Nothing leaves this device until redaction is previewed and granular consent is granted.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  child: const Text('Continue'),
                ),
              if (step > 0)
                TextButton(
                  onPressed: () => setState(() => step--),
                  child: const Text('Back'),
                ),
            ],
          ),
        ),
        steps: [
          Step(
            title: const Text('Select data'),
            isActive: step >= 0,
            content: const _Panel(
              icon: Icons.folder_open_outlined,
              title: 'Owned-device diagnostic log',
              detail:
                  'Simulated and synthetic captures are excluded automatically.',
            ),
          ),
          Step(
            title: const Text('Redaction Preview'),
            isActive: step >= 1,
            content: _Preview(preview: preview),
          ),
          Step(
            title: const Text('Consent'),
            isActive: step >= 2,
            content: Column(
              children: [
                CheckboxListTile(
                  value: logs,
                  onChanged: (value) => setState(() => logs = value ?? false),
                  title: const Text('Share redacted diagnostic logs'),
                ),
                CheckboxListTile(
                  value: notes,
                  onChanged: (value) => setState(() => notes = value ?? false),
                  title: const Text('Share engineer notes'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Submit'),
            isActive: step >= 3,
            content: _Panel(
              icon: Icons.cloud_off_outlined,
              title: 'Mock portal only',
              detail: logs || notes
                  ? 'Package is ready for the offline queue. Production upload is not configured.'
                  : 'Select at least one consent category.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.system_update_alt, color: SolarColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Library updates',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text(
                      'No production channel configured · last-known-good remains active',
                    ),
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

class _Panel extends StatelessWidget {
  const _Panel({required this.icon, required this.title, required this.detail});
  final IconData icon;
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
        Icon(icon, color: SolarColors.green),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SolarColors.deep,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          preview.redacted,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'monospace',
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${preview.changes.length} sensitive field redacted',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: SolarColors.green,
        ),
      ),
    ],
  );
}
