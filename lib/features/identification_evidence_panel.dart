import 'package:flutter/material.dart';
import '../identification/identification_state_machine.dart';

class IdentificationEvidencePanel extends StatelessWidget {
  const IdentificationEvidencePanel({required this.outcome, super.key});
  final IdentificationOutcome outcome;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How we identified this device',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (outcome.manuallySelected)
            const Text(
              'Manually selected — verify model and firmware before trusting decoded data.',
            ),
          if (outcome.evidence.isEmpty)
            const Text('No identification evidence is available.'),
          Wrap(
            spacing: 8,
            children: [
              for (final evidence in outcome.evidence)
                Chip(label: Text(evidence)),
            ],
          ),
        ],
      ),
    ),
  );
}
