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
  }) {
    if (!allowedFunctions.contains(function)) return false;
    if (function.isWrite) {
      return writeVerifiedOnHardware &&
          writeRanges.any((range) => range.contains(address, count));
    }
    return readRanges.any((range) => range.contains(address, count));
  }
}
