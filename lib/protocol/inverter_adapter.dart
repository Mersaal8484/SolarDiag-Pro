import '../core/inverter_models.dart';
import '../parameters/write_pipeline.dart';
import 'bms_adapter.dart';
import 'capabilities.dart';

abstract interface class InverterAdapter {
  Future<IdentificationResult> identify();
  Future<InverterTelemetrySnapshot> readTelemetry();
  Future<Set<String>> readAlarms();
  Future<Map<String, num>> readParameters();
  ParameterTransport parameterTransport();
  Future<CapabilitySet> capabilities();
  Future<LinkHealth> health();
}
