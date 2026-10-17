import 'dart:async';

class ModbusTimeout implements Exception {
  const ModbusTimeout();
  @override
  String toString() => 'Modbus request timed out.';
}

Future<T> withModbusTimeout<T>(Future<T> response, Duration timeout) async {
  try {
    return await response.timeout(timeout);
  } on TimeoutException {
    throw const ModbusTimeout();
  }
}
