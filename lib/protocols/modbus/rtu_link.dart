import 'dart:async';

import 'modbus_link.dart';
import 'modbus_models.dart';
import 'rtu_codec.dart';

class RtuLink implements ModbusLink {
  RtuLink({
    required this.transport,
    required this.baudRate,
    this.bitsPerCharacter = 11,
  });

  final ModbusByteTransport transport;
  final int baudRate;
  final int bitsPerCharacter;

  @override
  Future<List<int>> exchange(
    List<int> request, {
    required Duration timeout,
  }) async {
    if (request.length < 2 || request.length - 1 > 253) {
      throw const FormatException('Invalid normalized RTU request.');
    }
    final unitId = request.first;
    final functionCode = request[1];
    final data = request.sublist(2);
    final frame = const ModbusRtuCodec().encode(
      ModbusRtuFrame(
        address: unitId,
        functionCode: functionCode,
        data: data,
      ),
    );
    final expectedLength = switch (functionCode) {
      0x03 || 0x04 => _readResponseLength(request),
      0x10 => 8,
      _ => throw const FormatException('Unsupported RTU request function.'),
    };
    final response = await _collect(frame, expectedLength, timeout);
    if (response.length < 2 ||
        response[0] == 0 ||
        response[0] != unitId) {
      throw const FormatException('Invalid RTU response address.');
    }
    try {
      final decoded = const ModbusRtuCodec().decode(response);
      if (decoded.functionCode != functionCode) {
        throw const FormatException('RTU response function mismatch.');
      }
      await Future<void>.delayed(
        ModbusRtuCodec.interFrameDelay(
          baudRate,
          bitsPerCharacter: bitsPerCharacter,
        ),
      );
      return [unitId, decoded.functionCode, ...decoded.data];
    } on ModbusExceptionResponse catch (exception) {
      await Future<void>.delayed(
        ModbusRtuCodec.interFrameDelay(
          baudRate,
          bitsPerCharacter: bitsPerCharacter,
        ),
      );
      if (exception.functionCode != functionCode) {
        throw const FormatException('RTU exception function mismatch.');
      }
      return [unitId, exception.functionCode | 0x80, exception.exceptionCode];
    }
  }

  int _readResponseLength(List<int> request) {
    if (request.length != 6) {
      throw const FormatException('Malformed RTU register-read request.');
    }
    final count = request[4] << 8 | request[5];
    if (count < 1 || count > 125) {
      throw const FormatException('Invalid RTU register count.');
    }
    return 5 + count * 2;
  }

  Future<List<int>> _collect(
    List<int> request,
    int expectedLength,
    Duration timeout,
  ) async {
    final bytes = <int>[];
    await for (final chunk in transport.exchange(request).timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length >= 2 && bytes[1] & 0x80 != 0 && bytes.length >= 5) {
        if (bytes.length != 5) {
          throw const FormatException('RTU exception response length mismatch.');
        }
        return bytes;
      }
      if (bytes.length >= expectedLength) {
        if (bytes.length != expectedLength) {
          throw const FormatException('RTU response length mismatch.');
        }
        return bytes;
      }
      if (bytes.length > 256) {
        throw const FormatException('RTU response exceeds maximum frame size.');
      }
    }
    throw const FormatException('Incomplete RTU response.');
  }
}
