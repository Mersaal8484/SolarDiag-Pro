import 'modbus_models.dart';

class ModbusGuard {
  const ModbusGuard({
    required this.allowedFunctions,
    required this.readRanges,
    required this.writeRanges,
    required this.writeVerifiedOnHardware,
  });
  final Set<ModbusFunction> allowedFunctions;
  final List<RegisterRange> readRanges;
  final List<RegisterRange> writeRanges;
  final bool writeVerifiedOnHardware;

  bool allows({
    required ModbusFunction function,
    required int address,
    required int count,
    required bool pipelineAuthorized,
  }) {
    if (!allowedFunctions.contains(function)) return false;
    if (function.isWrite) {
      return pipelineAuthorized &&
          writeVerifiedOnHardware &&
          writeRanges.any((range) => range.contains(address, count));
    }
    return readRanges.any((range) => range.contains(address, count));
  }
}
