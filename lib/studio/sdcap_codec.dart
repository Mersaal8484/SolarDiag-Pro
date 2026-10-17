import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'capture_models.dart';

class SdcapDocument {
  const SdcapDocument({
    required this.session,
    required this.payloadHash,
    required this.sourceSchemaVersion,
  });
  final CaptureSession session;
  final String payloadHash;
  final int sourceSchemaVersion;
}

class SdcapCodec {
  const SdcapCodec();
  static const magic = 'SOLARDIAG_CAPTURE';
  static const schemaVersion = 2;

  String encode(CaptureSession session, {bool forLocalStorage = false}) {
    if (session.containsNdaMaterial && !forLocalStorage) {
      throw const FormatException(
        'NDA material is excluded from capture exports.',
      );
    }
    final payload = _payloadV2(session);
    final canonicalPayload = jsonEncode(payload);
    final hash = sha256.convert(utf8.encode(canonicalPayload)).toString();
    return jsonEncode({
      'magic': magic,
      'schema_version': schemaVersion,
      'payload': payload,
      'sha256': hash,
    });
  }

  SdcapDocument decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> || decoded['magic'] != magic) {
      throw const FormatException('Invalid .sdcap container.');
    }
    final version = decoded['schema_version'];
    final payload = decoded['payload'];
    final expectedHash = decoded['sha256'];
    if (version is! int ||
        (version != 1 && version != schemaVersion) ||
        payload is! Map<String, Object?> ||
        expectedHash is! String) {
      throw const FormatException('Unsupported or malformed .sdcap container.');
    }
    final actualHash = sha256
        .convert(utf8.encode(jsonEncode(payload)))
        .toString();
    if (actualHash != expectedHash) {
      throw const FormatException('Capture integrity check failed.');
    }
    final session = version == 1
        ? _decodeV1(payload, actualHash)
        : _decodeV2(payload, actualHash);
    return SdcapDocument(
      session: session,
      payloadHash: actualHash,
      sourceSchemaVersion: version,
    );
  }

  CaptureSession _decodeV2(Map<String, Object?> payload, String hash) {
    final rawFrames = _list(payload, 'frames', 'payload');
    final frames = <CapturedFrame>[];
    for (var index = 0; index < rawFrames.length; index++) {
      final raw = _mapValue(rawFrames[index], 'frames[$index]');
      frames.add(
        CapturedFrame(
          timestampNanos: _int(raw, 'timestamp_ns', 'frames[$index]'),
          rawBytes: _bytes(raw['raw_bytes'], 'frames[$index].raw_bytes'),
          direction: _enumValue(
            CaptureDirection.values,
            _string(raw, 'direction', 'frames[$index]'),
            'frames[$index].direction',
          ),
          channel: _string(raw, 'channel', 'frames[$index]'),
          sourceAddress: _optionalString(
            raw,
            'source_address',
            'frames[$index]',
          ),
          destinationAddress: _optionalString(
            raw,
            'destination_address',
            'frames[$index]',
          ),
          errorFlags: _strings(
            raw['error_flags'],
            'frames[$index].error_flags',
          ),
          protocolHint: _optionalString(raw, 'protocol_hint', 'frames[$index]'),
          identifier: _optionalInt(raw, 'can_identifier', 'frames[$index]'),
          extendedIdentifier:
              _optionalBool(raw, 'can_extended', 'frames[$index]') ?? false,
        ),
      );
    }
    return CaptureSession(
      id: _string(payload, 'id', 'payload'),
      interfaceType: _enumValue(
        CaptureInterface.values,
        _string(payload, 'interface', 'payload'),
        'payload.interface',
      ),
      source: _enumValue(
        CaptureSource.values,
        _string(payload, 'source', 'payload'),
        'payload.source',
      ),
      startedAt: _date(payload, 'started_at', 'payload'),
      frames: List.unmodifiable(frames),
      synthetic: _bool(payload, 'synthetic', 'payload'),
      containsNdaMaterial:
          _optionalBool(payload, 'nda_restricted', 'payload') ?? false,
      notes: _string(payload, 'notes', 'payload'),
      serialConfiguration: _objectMap(
        payload['serial_configuration'],
        'serial_configuration',
      ),
      canConfiguration: _objectMap(
        payload['can_configuration'],
        'can_configuration',
      ),
      networkConfiguration: _objectMap(
        payload['network_configuration'],
        'network_configuration',
      ),
      deviceMetadata: _stringMap(payload['device_metadata'], 'device_metadata'),
      clockSource: _string(payload, 'clock_source', 'payload'),
      clockAccuracyNanos: _optionalInt(payload, 'clock_accuracy_ns', 'payload'),
      integrityHash: hash,
    );
  }

  CaptureSession _decodeV1(Map<String, Object?> payload, String hash) {
    final rawFrames = _list(payload, 'frames', 'payload');
    final frames = <CapturedFrame>[];
    for (var index = 0; index < rawFrames.length; index++) {
      final raw = _mapValue(rawFrames[index], 'frames[$index]');
      frames.add(
        CapturedFrame(
          timestampMicros: _int(raw, 'timestamp_us', 'frames[$index]'),
          identifier: _int(raw, 'identifier', 'frames[$index]'),
          payload: _bytes(raw['payload'], 'frames[$index].payload'),
          received: _bool(raw, 'received', 'frames[$index]'),
          extendedIdentifier: _bool(raw, 'extended', 'frames[$index]'),
          channel: 'legacy',
          protocolHint: 'CAN',
        ),
      );
    }
    return CaptureSession(
      id: _string(payload, 'id', 'payload'),
      interfaceType: _enumValue(
        CaptureInterface.values,
        _string(payload, 'interface', 'payload'),
        'payload.interface',
      ),
      source: _enumValue(
        CaptureSource.values,
        _string(payload, 'source', 'payload'),
        'payload.source',
      ),
      startedAt: _date(payload, 'started_at', 'payload'),
      frames: List.unmodifiable(frames),
      synthetic: _bool(payload, 'synthetic', 'payload'),
      containsNdaMaterial: false,
      notes: _string(payload, 'notes', 'payload'),
      canConfiguration: const {'legacy_schema': 1},
      clockSource: 'legacy-microsecond-clock',
      clockAccuracyNanos: 1000,
      integrityHash: hash,
    );
  }

  Map<String, Object?> _payloadV2(CaptureSession session) => {
    'id': session.id,
    'interface': session.interfaceType.name,
    'source': session.source.name,
    'started_at': session.startedAt.toUtc().toIso8601String(),
    'synthetic': session.synthetic,
    'nda_restricted': session.containsNdaMaterial,
    'notes': session.notes,
    'serial_configuration': session.serialConfiguration,
    'can_configuration': session.canConfiguration,
    'network_configuration': session.networkConfiguration,
    'device_metadata': session.deviceMetadata,
    'clock_source': session.clockSource,
    'clock_accuracy_ns': session.clockAccuracyNanos,
    'frames': [
      for (final frame in session.frames)
        {
          'timestamp_ns': frame.timestampNanos,
          'raw_bytes': frame.rawBytes,
          'direction': frame.direction.name,
          'channel': frame.channel,
          'source_address': frame.sourceAddress,
          'destination_address': frame.destinationAddress,
          'error_flags': frame.errorFlags,
          'protocol_hint': frame.protocolHint,
          'can_identifier': frame.identifier,
          'can_extended': frame.extendedIdentifier,
        },
    ],
  };
}

Map<String, Object?> _mapValue(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$path must be an object.');
  }
  return value;
}

Map<String, Object?> _objectMap(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  try {
    return Map<String, Object?>.unmodifiable(
      value.map((key, item) => MapEntry(key.toString(), item)),
    );
  } on Object {
    throw FormatException('$path contains invalid values.');
  }
}

Map<String, String> _stringMap(Object? value, String path) {
  if (value is! Map || value.entries.any((entry) => entry.value is! String)) {
    throw FormatException('$path must be a string map.');
  }
  return Map<String, String>.unmodifiable(
    value.map((key, item) => MapEntry(key.toString(), item as String)),
  );
}

List<Object?> _list(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! List) {
    throw FormatException('$path.$key must be an array.');
  }
  return value;
}

List<int> _bytes(Object? value, String path) {
  if (value is! List ||
      value.any((byte) => byte is! int || byte < 0 || byte > 255)) {
    throw FormatException('$path must contain bytes in 0..255.');
  }
  return List<int>.unmodifiable(value.whereType<int>());
}

List<String> _strings(Object? value, String path) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$path must be a string array.');
  }
  return List<String>.unmodifiable(value.whereType<String>());
}

String _string(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! String) {
    throw FormatException('$path.$key must be a string.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$path.$key must be a string.');
  }
  return value;
}

int _int(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! int) {
    throw FormatException('$path.$key must be an integer.');
  }
  return value;
}

int? _optionalInt(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is! int) {
    throw FormatException('$path.$key must be an integer.');
  }
  return value;
}

bool _bool(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value is! bool) {
    throw FormatException('$path.$key must be a boolean.');
  }
  return value;
}

bool? _optionalBool(Map<String, Object?> map, String key, String path) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is! bool) {
    throw FormatException('$path.$key must be a boolean.');
  }
  return value;
}

DateTime _date(Map<String, Object?> map, String key, String path) {
  final value = _string(map, key, path);
  final date = DateTime.tryParse(value);
  if (date == null) {
    throw FormatException('$path.$key must be an ISO date.');
  }
  return date;
}

T _enumValue<T extends Enum>(List<T> values, String name, String path) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  throw FormatException('$path has unsupported value: $name');
}
