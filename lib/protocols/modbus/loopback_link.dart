import 'modbus_link.dart';
import 'modbus_models.dart';
import 'rtu_codec.dart';

class LoopbackLink implements ModbusLink {
  const LoopbackLink(this.adapter);

  final ModbusRtuResponder adapter;

  @override
  Future<List<int>> exchange(
    List<int> request, {
    required Duration timeout,
  }) async {
    if (request.length < 2 || request.length - 1 > 253) {
      throw const FormatException('Invalid normalized loopback request.');
    }
    final unitId = request.first;
    final pdu = request.sublist(1);
    final encoded = const ModbusRtuCodec().encode(
      ModbusRtuFrame(
        address: unitId,
        functionCode: pdu.first,
        data: pdu.sublist(1),
      ),
    );
    final response = adapter.respondRtu(encoded);
    if (response.isEmpty || response.first == 0) {
      throw const FormatException('Invalid RTU response address.');
    }
    try {
      final decoded = const ModbusRtuCodec().decode(response);
      return [decoded.address, decoded.functionCode, ...decoded.data];
    } on ModbusExceptionResponse catch (exception) {
      return [unitId, exception.functionCode | 0x80, exception.exceptionCode];
    }
  }
}
