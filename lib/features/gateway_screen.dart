import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme.dart';
import '../identification/identification_state_machine.dart';
import '../session/device_session.dart';
import 'identification_evidence_panel.dart';

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({this.identificationOutcome, super.key});
  final IdentificationOutcome? identificationOutcome;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.diagnosticGateway,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(s.gatewayDescription),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 24,
              runSpacing: 18,
              children: [
                _Status(
                  icon: Icons.visibility_outlined,
                  label: s.defaultMode,
                  value: s.listenOnly,
                ),
                _Status(
                  icon: Icons.thermostat_outlined,
                  label: s.gateway,
                  value: switch (session.linkState) {
                    DeviceSessionLinkState.connecting => s.connecting,
                    DeviceSessionLinkState.online => s.online,
                    DeviceSessionLinkState.unavailable => s.linkUnavailable,
                  },
                ),
                _Status(
                  icon: Icons.security,
                  label: s.transmissionGuard,
                  value: s.transmissionBlocked,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          s.connectionChecklist,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        for (final item in [
          s.isolatedInterfaceCheck,
          s.pinoutCheck,
          s.terminationCheck,
          s.transmissionBlockedCheck,
        ])
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_box_outline_blank),
              title: Text(item),
            ),
          ),
        const SizedBox(height: 18),
        if (identificationOutcome case final outcome?) ...[
          IdentificationEvidencePanel(outcome: outcome),
          const SizedBox(height: 18),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            'RS485',
            'RS232',
            'CAN 125k',
            'CAN 250k',
            'CAN 500k',
            'CAN 1M',
            'UART',
            'BLE',
          ].map((item) => Chip(label: Text(item))).toList(),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Row(
      children: [
        Icon(icon, color: SolarColors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                softWrap: true,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
