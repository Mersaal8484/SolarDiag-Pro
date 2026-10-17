import 'compatibility_models.dart';

class LinkObservation {
  const LinkObservation({
    required this.window,
    required this.expectedMessages,
    required this.receivedMessages,
    required this.timeouts,
    required this.crcFailures,
    required this.inverterSoc,
    required this.batterySoc,
  });
  final Duration window;
  final int expectedMessages;
  final int receivedMessages;
  final int timeouts;
  final int crcFailures;
  final SourcedValue<double> inverterSoc;
  final SourcedValue<double> batterySoc;
}

class LinkDiagnosticResult {
  const LinkDiagnosticResult({
    required this.state,
    required this.messageDeliveryRatio,
    required this.socDelta,
    required this.findings,
  });
  final CompatibilityState state;
  final double? messageDeliveryRatio;
  final double? socDelta;
  final List<CompatibilityFinding> findings;
}

class LinkDiagnostics {
  const LinkDiagnostics({
    this.minimumDeliveryRatio = .95,
    this.maximumSocDelta = 5,
  });
  final double minimumDeliveryRatio;
  final double maximumSocDelta;

  LinkDiagnosticResult analyze(LinkObservation observation) {
    final findings = <CompatibilityFinding>[];
    final ratio = observation.expectedMessages > 0
        ? observation.receivedMessages / observation.expectedMessages
        : null;
    if (ratio == null) {
      findings.add(
        const CompatibilityFinding(
          code: 'MESSAGE_DELIVERY',
          state: CompatibilityState.unknown,
          evidence: {},
          message: 'Expected message count is unavailable.',
        ),
      );
    } else {
      findings.add(
        CompatibilityFinding(
          code: 'MESSAGE_DELIVERY',
          state: ratio >= minimumDeliveryRatio
              ? CompatibilityState.compatible
              : CompatibilityState.attention,
          evidence: {
            'ratio': ratio,
            'received': observation.receivedMessages,
            'expected': observation.expectedMessages,
            'window_ms': observation.window.inMilliseconds,
          },
          message: ratio >= minimumDeliveryRatio
              ? 'Message delivery is within the configured quality threshold.'
              : 'Message delivery is below the configured quality threshold.',
        ),
      );
    }
    if (observation.timeouts > 0 || observation.crcFailures > 0) {
      findings.add(
        CompatibilityFinding(
          code: 'LINK_ERRORS',
          state: CompatibilityState.attention,
          evidence: {
            'timeouts': observation.timeouts,
            'crc_failures': observation.crcFailures,
          },
          message: 'The observation window contains transport errors.',
        ),
      );
    }
    double? socDelta;
    if (observation.inverterSoc.isAvailable &&
        observation.batterySoc.isAvailable) {
      socDelta =
          (observation.inverterSoc.value! - observation.batterySoc.value!)
              .abs();
      findings.add(
        CompatibilityFinding(
          code: 'SOC_CONSISTENCY',
          state: socDelta <= maximumSocDelta
              ? CompatibilityState.compatible
              : CompatibilityState.attention,
          evidence: {
            'inverter_soc': observation.inverterSoc.value,
            'battery_soc': observation.batterySoc.value,
            'delta_percent': socDelta,
          },
          message: socDelta <= maximumSocDelta
              ? 'Reported SOC values are consistent within the configured tolerance.'
              : 'Reported SOC values differ beyond the configured tolerance.',
        ),
      );
    } else {
      findings.add(
        const CompatibilityFinding(
          code: 'SOC_CONSISTENCY',
          state: CompatibilityState.unknown,
          evidence: {},
          message: 'Both SOC values are required for comparison.',
        ),
      );
    }
    final state =
        findings.any((item) => item.state == CompatibilityState.attention)
        ? CompatibilityState.attention
        : findings.any((item) => item.state == CompatibilityState.unknown)
        ? CompatibilityState.unknown
        : CompatibilityState.compatible;
    return LinkDiagnosticResult(
      state: state,
      messageDeliveryRatio: ratio,
      socDelta: socDelta,
      findings: List.unmodifiable(findings),
    );
  }
}
