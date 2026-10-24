import '../core/battery_models.dart';
import '../core/simulation_clock.dart';
import 'capabilities.dart';
import '../parameters/write_pipeline.dart';
import 'device_profile.dart';

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

class DeviceProfileIdentity {
  const DeviceProfileIdentity({
    required this.profileId,
    required this.model,
    required this.firmware,
    required this.deviceId,
  });

  final String profileId;
  final String model;
  final String firmware;
  final String deviceId;
}

abstract interface class BmsAdapter {
  DeviceProfileIdentity get profileIdentity;
  DeviceProfile? get activeProfile;
  SimulationClock? get simulationClock;
  Future<IdentificationResult> identify();
  Future<TelemetrySnapshot> readTelemetry();
  Future<List<Measurement>> readCellVoltages();
  Future<Set<String>> readAlarms();
  Future<Map<String, num>> readParameters();
  ParameterTransport parameterTransport();
  Future<CapabilitySet> capabilities();
  Future<LinkHealth> health();
}
