import 'dart:convert';

const maximumGatewayMessageBytes = 64 * 1024;

class GatewayMessage {
  const GatewayMessage({
    required this.sequence,
    required this.type,
    required this.payload,
  });

  final int sequence;
  final String type;
  final Map<String, Object?> payload;
}

class GatewayMessageCodec {
  const GatewayMessageCodec();

  String encode(GatewayMessage message) {
    _validate(message);
    final encoded = jsonEncode({
      'sequence': message.sequence,
      'type': message.type,
      'payload': message.payload,
    });
    if (utf8.encode(encoded).length > maximumGatewayMessageBytes) {
      throw const FormatException('Gateway message exceeds the size limit.');
    }
    return '$encoded\n';
  }

  GatewayMessage decode(String line) {
    if (utf8.encode(line).length > maximumGatewayMessageBytes) {
      throw const FormatException('Gateway message exceeds the size limit.');
    }
    final decoded = jsonDecode(line.trim());
    if (decoded is! Map<String, Object?> ||
        decoded['sequence'] is! int ||
        decoded['type'] is! String ||
        decoded['payload'] is! Map<String, Object?>) {
      throw const FormatException('Malformed gateway message.');
    }
    final message = GatewayMessage(
      sequence: decoded['sequence']! as int,
      type: decoded['type']! as String,
      payload: decoded['payload']! as Map<String, Object?>,
    );
    _validate(message);
    return message;
  }

  void _validate(GatewayMessage message) {
    if (message.sequence < 0 || message.type.trim().isEmpty) {
      throw const FormatException('Invalid gateway message metadata.');
    }
  }
}

class GatewaySequenceGuard {
  int? _lastSequence;

  void accept(GatewayMessage message) {
    final last = _lastSequence;
    if (last != null && message.sequence <= last) {
      throw const FormatException('Replayed or out-of-order gateway message.');
    }
    _lastSequence = message.sequence;
  }

  void reset() => _lastSequence = null;
}
