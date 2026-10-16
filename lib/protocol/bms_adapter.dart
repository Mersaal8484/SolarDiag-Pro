import '../core/battery_models.dart';
import 'capabilities.dart';

class IdentificationResult {
  const IdentificationResult({
    required this.confidence,
    required this.evidence,
    required this.candidateProfileIds,
  });
  final double confidence;
  final List<String> evidence;
  final List<String> candidateProfileIds;
}

class LinkHealth {
  const LinkHealth({
    required this.latency,
    required this.errorRate,
    required this.timeouts,
    required this.crcFailures,
  });
  final Duration latency;
  final double errorRate;
  final int timeouts;
  final int crcFailures;
}

abstract interface class BmsAdapter {
  Future<IdentificationResult> identify();
  Future<BatterySnapshot> readTelemetry();
  Future<List<double>> readCellVoltages();
  Future<CapabilitySet> capabilities();
  Future<LinkHealth> health();
}
