import 'dart:async';

import '../../parameters/write_pipeline.dart';
import 'modbus_guard.dart';
import 'modbus_link.dart';
import 'modbus_models.dart';

class ModbusGuardException implements Exception {
  const ModbusGuardException(this.reason);
  final String reason;
  @override
  String toString() => 'ModbusGuardException: $reason';
}

class ModbusTimeout implements Exception {
  const ModbusTimeout();
  @override
  String toString() => 'Modbus request timed out.';
}

class ModbusClient {
  const ModbusClient({
    required this.guard,
    required this.timeout,
    required this.link,
  });

  final ModbusGuard guard;
  final Duration timeout;
  final ModbusLink link;

  ModbusFunction checkRead({
    required int address,
    required int count,
    required int unitId,
  }) {
    _validateRange(address, count, unitId, maximumCount: 125);
    for (final function in [
      ModbusFunction.readHoldingRegisters,
      ModbusFunction.readInputRegisters,
    ]) {
      if (guard.allows(
        function: function,
        address: address,
        count: count,
      )) {
        return function;
      }
    }
    throw ModbusGuardException(
      'Read of $count register(s) at $address (unit $unitId) '
      'is not permitted by the active guard.',
    );
  }

  void checkWrite({
    required int address,
    required List<int> values,
    required int unitId,
    required PipelineWriteAuthorization? authorization,
  }) {
    _validateRange(address, values.length, unitId, maximumCount: 123);
    if (values.any((value) => value < 0 || value > 0xffff)) {
      throw ArgumentError.value(values, 'values');
    }
    final function = ModbusFunction.writeMultipleRegisters;
    if (!guard.allows(
      function: function,
      address: address,
      count: values.length,
    )) {
      throw ModbusGuardException(
        'Write of ${values.length} register(s) at $address '
        '(unit $unitId) is not permitted by the active guard.',
      );
    }
    if (authorization == null ||
        !authorization.consume(
          functionCode: function.code,
          address: address,
          values: values,
          now: DateTime.now().toUtc(),
        )) {
      throw const ModbusGuardException(
        'A valid, unused pipeline authorization is required.',
      );
    }
  }

  Future<List<int>> readRegisters(
    int address,
    int count, {
    required int unitId,
  }) async {
    final function = checkRead(
      address: address,
      count: count,
      unitId: unitId,
    );
    final request = [
      unitId,
      function.code,
      address >> 8,
      address & 0xff,
      count >> 8,
      count & 0xff,
    ];
    final response = await _exchange(request);
    _validateUnitAndException(response, unitId, function);
    final byteCount = count * 2;
    if (response.length != byteCount + 3 ||
        response[2] != byteCount ||
        response.length - 1 > 253) {
      throw const FormatException('Modbus read byte count mismatch.');
    }
    return List.unmodifiable([
      for (var index = 3; index < response.length; index += 2)
        response[index] << 8 | response[index + 1],
    ]);
  }

  Future<void> writeRegisters(
    int address,
    List<int> values, {
    required int unitId,
    required PipelineWriteAuthorization? authorization,
  }) async {
    checkWrite(
      address: address,
      values: values,
      unitId: unitId,
      authorization: authorization,
    );
    final request = <int>[
      unitId,
      ModbusFunction.writeMultipleRegisters.code,
      address >> 8,
      address & 0xff,
      values.length >> 8,
      values.length & 0xff,
      values.length * 2,
      for (final value in values) ...[value >> 8, value & 0xff],
    ];
    final response = await _exchange(request);
    _validateUnitAndException(
      response,
      unitId,
      ModbusFunction.writeMultipleRegisters,
    );
    if (response.length != 6 ||
        response[2] != (address >> 8) ||
        response[3] != (address & 0xff) ||
        response[4] != (values.length >> 8) ||
        response[5] != (values.length & 0xff)) {
      throw const FormatException('Modbus write acknowledgement mismatch.');
    }
  }

  Future<List<int>> _exchange(List<int> request) async {
    if (request.length - 1 > 253) {
      throw const FormatException('Modbus PDU exceeds 253 bytes.');
    }
    try {
      final response = await link.exchange(request, timeout: timeout)
          .timeout(timeout);
      if (response.length < 2 || response.length - 1 > 253) {
        throw const FormatException('Invalid or oversized Modbus response.');
      }
      return response;
    } on TimeoutException {
      throw const ModbusTimeout();
    }
  }

  void _validateUnitAndException(
    List<int> response,
    int unitId,
    ModbusFunction function,
  ) {
    if (response.first != unitId) {
      throw const FormatException('Modbus unit identifier mismatch.');
    }
    if (response[1] == (function.code | 0x80)) {
      if (response.length != 3) {
        throw const FormatException('Malformed Modbus exception response.');
      }
      throw ModbusExceptionResponse(
        functionCode: function.code,
        exceptionCode: response[2],
      );
    }
    if (response[1] != function.code) {
      throw const FormatException('Modbus function code mismatch.');
    }
  }

  void _validateRange(
    int address,
    int count,
    int unitId, {
    required int maximumCount,
  }) {
    if (address < 0 ||
        address > 0xffff ||
        count < 1 ||
        count > maximumCount ||
        address + count > 0x10000 ||
        unitId < 1 ||
        unitId > 247) {
      throw ArgumentError('Invalid Modbus unit, address, or register count.');
    }
  }
}

Future<T> withModbusTimeout<T>(Future<T> response, Duration timeout) async {
  try {
    return await response.timeout(timeout);
  } on TimeoutException {
    throw const ModbusTimeout();
  }
}
