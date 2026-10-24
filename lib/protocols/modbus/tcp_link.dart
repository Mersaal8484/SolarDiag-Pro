import 'dart:async';

import 'modbus_link.dart';
import 'tcp_codec.dart';

class TcpLink implements ModbusLink {
  TcpLink({required this.transport});

  final ModbusByteTransport transport;
  int _nextTransactionId = 0;

  @override
  Future<List<int>> exchange(
    List<int> request, {
    required Duration timeout,
  }) async {
    if (request.length < 2 || request.length - 1 > 253) {
      throw const FormatException('Invalid normalized TCP request.');
    }
    final unitId = request.first;
    if (unitId < 1 || unitId > 247) {
      throw const FormatException('Invalid Modbus unit identifier.');
    }
    final transactionId = _nextTransactionId;
    _nextTransactionId = (_nextTransactionId + 1) & 0xffff;
    final pdu = request.sublist(1);
    final encoded = const ModbusTcpCodec().encode(
      ModbusTcpFrame(
        transactionId: transactionId,
        unitId: unitId,
        functionCode: pdu.first,
        data: pdu.sublist(1),
      ),
    );
    final responseBytes = await _collect(encoded, timeout);
    final response = const ModbusTcpCodec().decode(responseBytes);
    if (response.transactionId != transactionId ||
        response.unitId != unitId) {
      throw const FormatException('MBAP transaction or unit identifier mismatch.');
    }
    return [unitId, response.functionCode, ...response.data];
  }

  Future<List<int>> _collect(List<int> request, Duration timeout) async {
    final bytes = <int>[];
    await for (final chunk in transport.exchange(request).timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length >= 6) {
        final length = bytes[4] << 8 | bytes[5];
        if (length < 2 || length - 1 > 253) {
          throw const FormatException('Invalid or oversized MBAP response.');
        }
        final expectedLength = length + 6;
        if (bytes.length >= expectedLength) {
          if (bytes.length != expectedLength) {
            throw const FormatException('MBAP response length mismatch.');
          }
          return bytes;
        }
      }
      if (bytes.length > 259) {
        throw const FormatException('MBAP response exceeds maximum size.');
      }
    }
    throw const FormatException('Incomplete MBAP response.');
  }
}
