import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../identification/identification_state_machine.dart';
import '../l10n/generated/app_localizations.dart';

class IdentificationEvidencePanel extends StatelessWidget {
  const IdentificationEvidencePanel({required this.outcome, super.key});
  final IdentificationOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PrecisionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.identificationEvidence,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (outcome.manuallySelected) Text(l10n.manualSelectionWarning),
            if (outcome.evidence.isEmpty) Text(l10n.noIdentificationEvidence),
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
}
