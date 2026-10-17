import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'capture_models.dart';
import 'findings.dart';
import 'sdcap_codec.dart';

class ResearchBundle {
  const ResearchBundle({
    required this.sessions,
    required this.findings,
    required this.referenceIds,
    required this.payloadHash,
  });

  final List<CaptureSession> sessions;
  final List<ProtocolFinding> findings;
  final List<String> referenceIds;
  final String payloadHash;
}

class ResearchBundleCodec {
  const ResearchBundleCodec({this.captureCodec = const SdcapCodec()});

  static const magic = 'SOLARDIAG_RESEARCH_BUNDLE';
  static const schemaVersion = 1;
  final SdcapCodec captureCodec;

  String encode({
    required Iterable<CaptureSession> sessions,
    required Iterable<ProtocolFinding> findings,
    Iterable<String> referenceIds = const [],
  }) {
    final captureDocuments = [
      for (final session in sessions)
        jsonDecode(captureCodec.encode(session)) as Map<String, Object?>,
    ];
    final payload = <String, Object?>{
      'sessions': captureDocuments,
      'findings': [for (final finding in findings) finding.toJson()],
      'reference_ids': referenceIds.toSet().toList()..sort(),
    };
    final canonical = jsonEncode(payload);
    final hash = sha256.convert(utf8.encode(canonical)).toString();
    return jsonEncode({
      'magic': magic,
      'schema_version': schemaVersion,
      'payload': payload,
      'sha256': hash,
    });
  }

  ResearchBundle decode(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, Object?> ||
        root['magic'] != magic ||
        root['schema_version'] != schemaVersion) {
      throw const FormatException('Invalid research bundle container.');
    }
    final payload = root['payload'];
    final expectedHash = root['sha256'];
    if (payload is! Map<String, Object?> || expectedHash is! String) {
      throw const FormatException('Invalid research bundle payload.');
    }
    final actualHash = sha256
        .convert(utf8.encode(jsonEncode(payload)))
        .toString();
    if (actualHash != expectedHash) {
      throw const FormatException('Research bundle integrity check failed.');
    }
    final sessionsJson = payload['sessions'];
    final findingsJson = payload['findings'];
    final referencesJson = payload['reference_ids'];
    if (sessionsJson is! List ||
        findingsJson is! List ||
        referencesJson is! List) {
      throw const FormatException('Invalid research bundle collections.');
    }
    return ResearchBundle(
      sessions: List.unmodifiable(
        sessionsJson.map(
          (document) => captureCodec.decode(jsonEncode(document)).session,
        ),
      ),
      findings: List.unmodifiable(
        findingsJson.map((document) {
          if (document is! Map<String, Object?>) {
            throw const FormatException('Invalid bundled finding.');
          }
          return ProtocolFinding.fromJson(document);
        }),
      ),
      referenceIds: List.unmodifiable(
        referencesJson.map((value) {
          if (value is! String) {
            throw const FormatException('Invalid bundled reference ID.');
          }
          return value;
        }),
      ),
      payloadHash: actualHash,
    );
  }
}
