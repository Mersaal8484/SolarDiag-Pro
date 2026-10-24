class ModbusTcpFrame {
  const ModbusTcpFrame({
    required this.transactionId,
    required this.unitId,
    required this.functionCode,
    required this.data,
  });
  final int transactionId;
  final int unitId;
  final int functionCode;
  final List<int> data;
}

class ModbusTcpCodec {
  const ModbusTcpCodec();
  List<int> encode(ModbusTcpFrame frame) {
    if (frame.transactionId < 0 ||
        frame.transactionId > 0xffff ||
        frame.unitId < 0 ||
        frame.unitId > 0xff) {
      throw const FormatException('Invalid MBAP identifiers.');
    }
    if (frame.data.length + 1 > 253) {
      throw const FormatException('Modbus PDU exceeds 253 bytes.');
    }
    final length = frame.data.length + 2;
    return [
      frame.transactionId >> 8,
      frame.transactionId & 0xff,
      0,
      0,
      length >> 8,
      length & 0xff,
      frame.unitId,
      frame.functionCode,
      ...frame.data,
    ];
  }

  ModbusTcpFrame decode(List<int> bytes) {
    if (bytes.length < 8) throw const FormatException('Partial MBAP frame.');
    if (bytes[2] != 0 || bytes[3] != 0) {
      throw const FormatException('MBAP protocol identifier must be zero.');
    }
    final length = bytes[4] << 8 | bytes[5];
    if (length < 2 || bytes.length != 6 + length) {
      throw const FormatException('Invalid MBAP length.');
    }
    if (length - 1 > 253) {
      throw const FormatException('Modbus PDU exceeds 253 bytes.');
    }
    return ModbusTcpFrame(
      transactionId: bytes[0] << 8 | bytes[1],
      unitId: bytes[6],
      functionCode: bytes[7],
      data: List.unmodifiable(bytes.sublist(8)),
    );
  }
}
