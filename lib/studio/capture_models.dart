enum CaptureInterface { can, rs485, rs232, uart, ble, ethernet, imported }

enum CaptureSource {
  passiveGateway,
  sdcap,
  genericText,
  candump,
  csv,
  slcan,
  peakTrc,
  pcap,
  vectorAsc,
  synthetic,
}

enum CaptureDirection { tx, rx, unknown }

class CapturedFrame {
  const CapturedFrame({
    int? timestampNanos,
    int? timestampMicros,
    List<int>? rawBytes,
    List<int>? payload,
    CaptureDirection? direction,
    bool? received,
    this.channel = 'default',
    this.sourceAddress,
    this.destinationAddress,
    this.errorFlags = const [],
    this.protocolHint,
    this.identifier,
    this.extendedIdentifier = false,
  }) : timestampNanos = timestampNanos ?? (timestampMicros ?? 0) * 1000,
       rawBytes = rawBytes ?? payload ?? const [],
       direction =
           direction ??
           (received == null
               ? CaptureDirection.unknown
               : received
               ? CaptureDirection.rx
               : CaptureDirection.tx);

  final int timestampNanos;
  final List<int> rawBytes;
  final CaptureDirection direction;
  final String channel;
  final String? sourceAddress;
  final String? destinationAddress;
  final List<String> errorFlags;
  final String? protocolHint;
  final int? identifier;
  final bool extendedIdentifier;

  int get timestampMicros => timestampNanos ~/ 1000;
  List<int> get payload => rawBytes;
  bool get received => direction == CaptureDirection.rx;
}

typedef CaptureFrame = CapturedFrame;

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
    this.serialConfiguration = const {},
    this.canConfiguration = const {},
    this.networkConfiguration = const {},
    this.deviceMetadata = const {},
    this.clockSource = 'unspecified',
    this.clockAccuracyNanos,
    this.integrityHash,
  });

  final String id;
  final CaptureInterface interfaceType;
  final CaptureSource source;
  final DateTime startedAt;
  final List<CapturedFrame> frames;
  final bool synthetic;
  final bool containsNdaMaterial;
  final String notes;
  final Map<String, Object?> serialConfiguration;
  final Map<String, Object?> canConfiguration;
  final Map<String, Object?> networkConfiguration;
  final Map<String, String> deviceMetadata;
  final String clockSource;
  final int? clockAccuracyNanos;
  final String? integrityHash;

  CaptureSession withIntegrityHash(String hash) => CaptureSession(
    id: id,
    interfaceType: interfaceType,
    source: source,
    startedAt: startedAt,
    frames: frames,
    synthetic: synthetic,
    containsNdaMaterial: containsNdaMaterial,
    notes: notes,
    serialConfiguration: serialConfiguration,
    canConfiguration: canConfiguration,
    networkConfiguration: networkConfiguration,
    deviceMetadata: deviceMetadata,
    clockSource: clockSource,
    clockAccuracyNanos: clockAccuracyNanos,
    integrityHash: hash,
  );
}
