import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../design/accessibility.dart';
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
                  icon: SolarIcons.readOnly,
                  label: s.operatingMode,
                  value: switch (gateway.mode) {
                    GatewayOperatingMode.listenOnly => s.listenOnly,
                    GatewayOperatingMode.activeRead => s.activeRead,
                    GatewayOperatingMode.write => s.writeMode,
                  },
                ),
                _Status(
                  icon: SolarIcons.gateway,
                  label: s.gateway,
                  value: switch (session.linkState) {
                    DeviceSessionLinkState.connecting => s.connecting,
                    DeviceSessionLinkState.online => s.online,
                    DeviceSessionLinkState.unavailable => s.linkUnavailable,
                  },
                ),
                _Status(
                  icon: SolarIcons.locked,
                  label: s.transmissionGuard,
                  value: gateway.lastDecision == null
                      ? s.noTransmissionAttempted
                      : gateway.lastDecision!.allowed
                      ? s.guardAllowed
                      : s.guardBlocked,
                ),
                _Status(
                  icon: SolarIcons.confirmedCheck,
                  label: s.allowedFrames,
                  value: localizedNumber(
                    context,
                    gateway.allowedFrames,
                    fractionDigits: 0,
                  ),
                ),
                _Status(
                  icon: SolarIcons.critical,
                  label: s.blockedFrames,
                  value: localizedNumber(
                    context,
                    gateway.blockedFrames,
                    fractionDigits: 0,
                  ),
                ),
                _Status(
                  icon: SolarIcons.warning,
                  label: s.droppedFrames,
                  value: localizedNumber(
                    context,
                    gateway.droppedFrames,
                    fractionDigits: 0,
                  ),
                ),
                _Status(
                  icon: SolarIcons.currentFlow,
                  label: s.observedBusLoad,
                  value:
                      '${localizedNumber(context, gateway.observedBusLoad * 100, fractionDigits: 1)}%',
                ),
                _Status(
                  icon: SolarIcons.linkDiagnostics,
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
              leading: const SolarIcon(SolarIcons.evidence),
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
  final SolarIconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
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
