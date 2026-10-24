import 'package:flutter/material.dart';
import '../design/precision_ui.dart';
import '../l10n/generated/app_localizations.dart';
import '../app/theme.dart';
import '../identification/identification_state_machine.dart';
import '../session/device_session.dart';
import '../gateway/gateway_contract.dart';
import '../transport/safe_frame_transport.dart';
import 'identification_evidence_panel.dart';

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({this.identificationOutcome, super.key});
  final IdentificationOutcome? identificationOutcome;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final gateway = session.gatewayStatus;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PrecisionPageHeading(
          title: s.diagnosticGateway,
          subtitle: s.gatewayDescription,
          icon: Icons.settings_input_antenna_outlined,
        ),
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
                  label: s.operatingMode,
                  value: switch (gateway.mode) {
                    GatewayOperatingMode.listenOnly => s.listenOnly,
                    GatewayOperatingMode.activeRead => s.activeRead,
                    GatewayOperatingMode.write => s.writeMode,
                  },
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
                  value: gateway.lastDecision == null
                      ? s.noTransmissionAttempted
                      : gateway.lastDecision!.allowed
                      ? s.guardAllowed
                      : s.guardBlocked,
                ),
                _Status(
                  icon: Icons.check_circle_outline,
                  label: s.allowedFrames,
                  value: '${gateway.allowedFrames}',
                ),
                _Status(
                  icon: Icons.block_outlined,
                  label: s.blockedFrames,
                  value: '${gateway.blockedFrames}',
                ),
                _Status(
                  icon: Icons.delete_outline,
                  label: s.droppedFrames,
                  value: '${gateway.droppedFrames}',
                ),
                _Status(
                  icon: Icons.speed_outlined,
                  label: s.observedBusLoad,
                  value:
                      '${(gateway.observedBusLoad * 100).toStringAsFixed(1)}%',
                ),
                _Status(
                  icon: Icons.handshake_outlined,
                  label: s.negotiationState,
                  value: switch (gateway.negotiationState) {
                    GatewayNegotiationState.notNegotiated => s.notNegotiated,
                    GatewayNegotiationState.passiveAccepted =>
                      s.passiveNegotiated,
                    GatewayNegotiationState.activeReadAccepted =>
                      s.activeReadNegotiated,
                    GatewayNegotiationState.writeAccepted => s.writeNegotiated,
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (gateway.lastDecision case final decision?) ...[
          Text(
            s.lastGuardDecision,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(decision.reason, key: const Key('gateway-last-decision-reason')),
          const SizedBox(height: 18),
        ],
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
    width: 215,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: SolarColors.green.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: SolarColors.green, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
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
    ),
  );
}
