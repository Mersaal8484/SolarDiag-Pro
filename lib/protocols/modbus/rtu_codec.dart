import 'crc16.dart';
import 'modbus_models.dart';

class ModbusRtuFrame {
  const ModbusRtuFrame({
    required this.address,
    required this.functionCode,
    required this.data,
  });
  final int address;
  final int functionCode;
  final List<int> data;
  bool get isBroadcast => address == 0;
  bool get isException => functionCode & 0x80 != 0;
}

class ModbusRtuCodec {
  const ModbusRtuCodec();
  List<int> encode(ModbusRtuFrame frame) {
    if (frame.address < 0 || frame.address > 247) {
      throw const FormatException('RTU address must be 0–247.');
    }
    final function = ModbusFunction.fromCode(frame.functionCode);
    if (function == null) {
      throw const FormatException('Unsupported Modbus function.');
    }
    if (frame.isBroadcast && !function.isWrite) {
      throw const FormatException('Broadcast reads are prohibited.');
    }
    final bytes = [frame.address, frame.functionCode, ...frame.data];
    final crc = ModbusCrc16.calculate(bytes);
    return [...bytes, crc & 0xff, crc >> 8];
  }

  ModbusRtuFrame decode(List<int> bytes) {
    if (bytes.length < 5 || !ModbusCrc16.valid(bytes)) {
      throw const FormatException('Malformed RTU frame or CRC mismatch.');
    }
    final address = bytes[0];
    if (address > 247) throw const FormatException('Invalid RTU address.');
    final functionCode = bytes[1];
    if (functionCode & 0x80 != 0) {
      if (bytes.length != 5) {
        throw const FormatException('Malformed exception response.');
      }
      throw ModbusExceptionResponse(
        functionCode: functionCode & 0x7f,
        exceptionCode: bytes[2],
      );
    }
    if (ModbusFunction.fromCode(functionCode) == null) {
      throw const FormatException('Unsupported Modbus function.');
    }
    return ModbusRtuFrame(
      address: address,
      functionCode: functionCode,
      data: List.unmodifiable(bytes.sublist(2, bytes.length - 2)),
    );
  }

  static Duration interFrameDelay(int baudRate, {int bitsPerCharacter = 11}) {
    if (baudRate <= 0) throw ArgumentError.value(baudRate, 'baudRate');
    final micros = (3500000 * bitsPerCharacter / baudRate).ceil();
    return Duration(microseconds: baudRate > 19200 ? 1750 : micros);
  }
}

class ModbusRtuStreamDecoder {
  ModbusRtuStreamDecoder({this.maximumFrameLength = 256});
  final int maximumFrameLength;
  final List<int> _buffer = [];
  List<ModbusRtuFrame> add(List<int> bytes) {
    _buffer.addAll(bytes);
    if (_buffer.length > maximumFrameLength * 2) {
      _buffer.removeRange(0, _buffer.length - maximumFrameLength);
    }
    final frames = <ModbusRtuFrame>[];
    while (_buffer.length >= 5) {
      var found = false;
      for (var start = 0; start <= _buffer.length - 5 && !found; start++) {
        for (
          var end = start + 5;
          end <= _buffer.length && end - start <= maximumFrameLength;
          end++
        ) {
          final candidate = _buffer.sublist(start, end);
          if (!ModbusCrc16.valid(candidate)) continue;
          try {
            frames.add(const ModbusRtuCodec().decode(candidate));
            _buffer.removeRange(0, end);
            found = true;
            break;
          } on ModbusExceptionResponse {
            rethrow;
          } on FormatException {
            continue;
          }
        }
      }
      if (!found) {
        if (_buffer.length > maximumFrameLength) _buffer.removeAt(0);
        break;
      }
    }
    return frames;
  }
}
