import '../core/battery_models.dart';
import 'capabilities.dart';
import '../parameters/write_pipeline.dart';

class IdentificationResult {
  const IdentificationResult({
    required this.confidence,
    required this.evidence,
    required this.candidateProfileIds,
    this.model,
    this.firmware,
  });
  final double confidence;
  final List<String> evidence;
  final List<String> candidateProfileIds;
  final String? model;
  final String? firmware;
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
  Future<TelemetrySnapshot> readTelemetry();
  Future<List<Measurement>> readCellVoltages();
  Future<Set<String>> readAlarms();
  Future<Map<String, num>> readParameters();
  ParameterTransport parameterTransport();
  Future<CapabilitySet> capabilities();
  Future<LinkHealth> health();
}
