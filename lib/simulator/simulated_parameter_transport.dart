import '../parameters/write_pipeline.dart';

abstract class SimulatedParameterBackend {
  const SimulatedParameterBackend();

  Future<num> readParameter(String id);
  Future<Map<String, num>> readConfiguration();
  Future<void> applyRawParameter(
    String id,
    int rawValue,
    String idempotencyKey,
  );
}

ParameterTransport createSimulatedParameterTransport(
  SimulatedParameterBackend backend,
) => ParameterTransport.simulator(
  read: backend.readParameter,
  readAll: backend.readConfiguration,
  write: backend.applyRawParameter,
);
