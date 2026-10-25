enum ModbusFunction {
  readCoils(0x01, false),
  readDiscreteInputs(0x02, false),
  readHoldingRegisters(0x03, false),
  readInputRegisters(0x04, false),
  writeSingleCoil(0x05, true),
  writeSingleRegister(0x06, true),
  writeMultipleCoils(0x0f, true),
  writeMultipleRegisters(0x10, true);

  const ModbusFunction(this.code, this.isWrite);
  final int code;
  final bool isWrite;
  static ModbusFunction? fromCode(int code) => switch (code) {
    0x01 => readCoils,
    0x02 => readDiscreteInputs,
    0x03 => readHoldingRegisters,
    0x04 => readInputRegisters,
    0x05 => writeSingleCoil,
    0x06 => writeSingleRegister,
    0x0f => writeMultipleCoils,
    0x10 => writeMultipleRegisters,
    _ => null,
  };
}

enum ModbusRegisterKind {
  holding(ModbusFunction.readHoldingRegisters),
  input(ModbusFunction.readInputRegisters);

  const ModbusRegisterKind(this.function);

  final ModbusFunction function;
}

class ModbusExceptionResponse implements Exception {
  const ModbusExceptionResponse({
    required this.functionCode,
    required this.exceptionCode,
  });
  final int functionCode;
  final int exceptionCode;
  @override
  String toString() =>
      'Modbus exception $exceptionCode for function $functionCode';
}

class RegisterRange {
  const RegisterRange(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);
  final int start;
  final int end;
  bool contains(int address, int count) =>
      count > 0 && address >= start && address + count - 1 <= end;
}
