part of '../parameters/write_pipeline.dart';

sealed class SimulatedParameterBackend {
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
) => ParameterTransport._simulator(
  read: backend.readParameter,
  readAll: backend.readConfiguration,
  write: backend.applyRawParameter,
);
