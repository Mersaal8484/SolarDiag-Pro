enum CaptureInterface { can, rs485, rs232, uart, ble, imported }

enum CaptureSource { passiveGateway, candump, csv, synthetic }

class CaptureFrame {
  const CaptureFrame({
    required this.timestampMicros,
    required this.identifier,
    required this.payload,
    required this.received,
    this.extendedIdentifier = false,
  });
  final int timestampMicros;
  final int identifier;
  final List<int> payload;
  final bool received;
  final bool extendedIdentifier;
}

class CaptureSession {
  const CaptureSession({
    required this.id,
    required this.interfaceType,
    required this.source,
    required this.startedAt,
    required this.frames,
    required this.synthetic,
    required this.containsNdaMaterial,
    required this.notes,
  });
  final String id;
  final CaptureInterface interfaceType;
  final CaptureSource source;
  final DateTime startedAt;
  final List<CaptureFrame> frames;
  final bool synthetic;
  final bool containsNdaMaterial;
  final String notes;
}
