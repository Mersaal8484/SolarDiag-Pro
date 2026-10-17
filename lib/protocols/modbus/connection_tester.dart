import 'modbus_guard.dart';
import 'modbus_models.dart';

class ConnectionTestResult {
  const ConnectionTestResult({required this.enabled, required this.message});
  final bool enabled;
  final String message;
}

class ModbusConnectionTester {
  const ModbusConnectionTester(this.guard);
  final ModbusGuard guard;
  ConnectionTestResult inspect() {
    if (guard.readRanges.isEmpty) {
      return const ConnectionTestResult(
        enabled: false,
        message: 'Register map required from manufacturer.',
      );
    }
    final range = guard.readRanges.first;
    final allowed = guard.allows(
      function: ModbusFunction.readHoldingRegisters,
      address: range.start,
      count: 1,
      pipelineAuthorized: false,
    );
    return ConnectionTestResult(
      enabled: allowed,
      message: allowed
          ? 'Read-only connection test is available.'
          : 'No permitted read function.',
    );
  }
}
