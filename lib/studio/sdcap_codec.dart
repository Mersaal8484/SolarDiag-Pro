import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'capture_models.dart';

class SdcapDocument {
  const SdcapDocument({required this.session, required this.payloadHash});
  final CaptureSession session;
  final String payloadHash;
}

class SdcapCodec {
  const SdcapCodec();
  static const magic = 'SOLARDIAG_CAPTURE';
  static const schemaVersion = 1;

  String encode(CaptureSession session) {
    if (session.containsNdaMaterial) {
      throw const FormatException(
        'NDA material is excluded from capture exports.',
      );
    }
    final payload = _payload(session);
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
    final root = jsonDecode(source);
    if (root is! Map<String, Object?> ||
        root['magic'] != magic ||
        root['schema_version'] != schemaVersion ||
        root['payload'] is! Map<String, Object?> ||
        root['sha256'] is! String) {
      throw const FormatException('Invalid .sdcap container.');
    }
    final payload = root['payload']! as Map<String, Object?>;
    final actual = sha256.convert(utf8.encode(jsonEncode(payload))).toString();
    if (actual != root['sha256']) {
      throw const FormatException('Capture integrity check failed.');
    }
    final rawFrames = payload['frames'];
    if (rawFrames is! List) {
      throw const FormatException('Capture frames must be an array.');
    }
    final frames = rawFrames
        .map((raw) {
          if (raw is! Map<String, Object?> || raw['payload'] is! List) {
            throw const FormatException('Malformed capture frame.');
          }
          final bytes = (raw['payload']! as List).cast<int>();
          if (bytes.any((byte) => byte < 0 || byte > 255)) {
            throw const FormatException('Capture byte is outside 0..255.');
          }
          return CaptureFrame(
            timestampMicros: raw['timestamp_us'] as int,
            identifier: raw['identifier'] as int,
            payload: List.unmodifiable(bytes),
            received: raw['received'] as bool,
            extendedIdentifier: raw['extended'] as bool,
          );
        })
        .toList(growable: false);
    return SdcapDocument(
      session: CaptureSession(
        id: payload['id'] as String,
        interfaceType: CaptureInterface.values.byName(
          payload['interface'] as String,
        ),
        source: CaptureSource.values.byName(payload['source'] as String),
        startedAt: DateTime.parse(payload['started_at'] as String),
        frames: frames,
        synthetic: payload['synthetic'] as bool,
        containsNdaMaterial: false,
        notes: payload['notes'] as String,
      ),
      payloadHash: actual,
    );
  }

  Map<String, Object?> _payload(CaptureSession session) => {
    'id': session.id,
    'interface': session.interfaceType.name,
    'source': session.source.name,
    'started_at': session.startedAt.toUtc().toIso8601String(),
    'synthetic': session.synthetic,
    'notes': session.notes,
    'frames': [
      for (final frame in session.frames)
        {
          'timestamp_us': frame.timestampMicros,
          'identifier': frame.identifier,
          'payload': frame.payload,
          'received': frame.received,
          'extended': frame.extendedIdentifier,
        },
    ],
  };
}
