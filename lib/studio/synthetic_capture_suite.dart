import 'capture_models.dart';

abstract final class SyntheticCaptureSuite {
  static List<CaptureSession> get all => [
    canCounter,
    modbusPolling,
    noisySerial,
  ];

  static final canCounter = CaptureSession(
    id: 'synthetic-can-counter',
    interfaceType: CaptureInterface.can,
    source: CaptureSource.synthetic,
    startedAt: DateTime.utc(2026, 1, 1),
    frames: [
      for (var index = 0; index < 16; index++)
        CapturedFrame(
          timestampNanos: index * 100000000,
          rawBytes: [0x02, 0x28, index],
          direction: CaptureDirection.rx,
          channel: 'can0',
          protocolHint: 'Synthetic CAN',
          identifier: 0x351,
        ),
    ],
    synthetic: true,
    containsNdaMaterial: false,
    notes: 'Deterministic CAN byte-counter fixture.',
    canConfiguration: const {'bitrate': 500000, 'listen_only': true},
    clockSource: 'synthetic-monotonic',
    clockAccuracyNanos: 1,
  );

  static final modbusPolling = CaptureSession(
    id: 'synthetic-modbus-polling',
    interfaceType: CaptureInterface.rs485,
    source: CaptureSource.synthetic,
    startedAt: DateTime.utc(2026, 1, 2),
    frames: [
      for (var cycle = 0; cycle < 4; cycle++) ...[
        CapturedFrame(
          timestampNanos: cycle * 1000000000,
          rawBytes: const [1, 3, 0, 0, 0, 2, 0xc4, 0x0b],
          direction: CaptureDirection.tx,
          channel: 'rs485-a',
          sourceAddress: 'master',
          destinationAddress: '1',
          protocolHint: 'Modbus RTU',
        ),
        CapturedFrame(
          timestampNanos: cycle * 1000000000 + 5000000,
          rawBytes: [1, 3, 4, 0, 80 + cycle, 0, 20 + cycle],
          direction: CaptureDirection.rx,
          channel: 'rs485-a',
          sourceAddress: '1',
          destinationAddress: 'master',
          protocolHint: 'Modbus RTU',
        ),
      ],
    ],
    synthetic: true,
    containsNdaMaterial: false,
    notes: 'Deterministic Modbus request/response polling fixture.',
    serialConfiguration: const {'baud_rate': 9600, 'format': '8N1'},
    clockSource: 'synthetic-monotonic',
    clockAccuracyNanos: 1,
  );

  static final noisySerial = CaptureSession(
    id: 'synthetic-noisy-serial',
    interfaceType: CaptureInterface.uart,
    source: CaptureSource.synthetic,
    startedAt: DateTime.utc(2026, 1, 3),
    frames: const [
      CapturedFrame(
        timestampNanos: 0,
        rawBytes: [0xaa, 0x03, 0x10, 0x20],
        direction: CaptureDirection.rx,
        channel: 'uart0',
        protocolHint: 'Unknown framed serial',
      ),
      CapturedFrame(
        timestampNanos: 2000000,
        rawBytes: [0xaa, 0x03, 0x10],
        direction: CaptureDirection.rx,
        channel: 'uart0',
        errorFlags: ['truncated', 'framing_error'],
        protocolHint: 'Unknown framed serial',
      ),
      CapturedFrame(
        timestampNanos: 12000000,
        rawBytes: [0xaa, 0x03, 0x11, 0x21],
        direction: CaptureDirection.rx,
        channel: 'uart0',
        protocolHint: 'Unknown framed serial',
      ),
    ],
    synthetic: true,
    containsNdaMaterial: false,
    notes: 'Malformed and valid serial frames for tolerant analysis.',
    serialConfiguration: {'baud_rate': 115200, 'format': '8N1'},
    clockSource: 'synthetic-monotonic',
    clockAccuracyNanos: 1,
  );
}
