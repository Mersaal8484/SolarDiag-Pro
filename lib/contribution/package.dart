import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'consent.dart';
import 'redaction.dart';

class ContributionPackage {
  const ContributionPackage({
    required this.manifest,
    required this.payload,
    required this.hash,
    required this.signature,
  });
  final Map<String, Object?> manifest;
  final String payload;
  final String hash;
  final String signature;
  String encode() => jsonEncode({
    'magic': 'SOLARDIAG_CONTRIBUTION',
    'manifest': manifest,
    'payload': payload,
    'sha256': hash,
    'signature': signature,
  });
}

class ContributionPackager {
  const ContributionPackager();
  ContributionPackage create({
    required String rawPayload,
    required String manufacturer,
    required String model,
    required String firmware,
    required String pseudonymousContributorId,
    required ContributionConsent consent,
    required bool synthetic,
    required String sessionSalt,
    required List<int> installationKey,
  }) {
    if (synthetic) {
      throw StateError('Synthetic or simulated data cannot be submitted.');
    }
    if (!consent.isValid) {
      throw StateError('A valid granular consent record is required.');
    }
    final redaction = const ContributionRedactor().redact(
      rawPayload,
      sessionSalt: sessionSalt,
    );
    final manifest = <String, Object?>{
      'schema_version': 1,
      'manufacturer': manufacturer,
      'model': model,
      'firmware': firmware,
      'contributor_id': pseudonymousContributorId,
      'synthetic': false,
      'consent': {
        'logs': consent.logs,
        'samples': consent.samples,
        'notes': consent.notes,
        'device_identity': consent.deviceIdentity,
        'granted_at': consent.grantedAt.toUtc().toIso8601String(),
        'version': consent.consentVersion,
      },
      'redaction_report': {
        'changes': redaction.changes.length,
        'kinds': redaction.changes.map((item) => item.kind).toSet().toList(),
      },
    };
    final content = '${jsonEncode(manifest)}|${redaction.redacted}';
    final hash = sha256.convert(utf8.encode(content)).toString();
    final signature = Hmac(
      sha256,
      installationKey,
    ).convert(utf8.encode(hash)).toString();
    return ContributionPackage(
      manifest: Map.unmodifiable(manifest),
      payload: redaction.redacted,
      hash: hash,
      signature: signature,
    );
  }

  bool verify(ContributionPackage package, List<int> installationKey) {
    final hash = sha256
        .convert(
          utf8.encode('${jsonEncode(package.manifest)}|${package.payload}'),
        )
        .toString();
    final signature = Hmac(
      sha256,
      installationKey,
    ).convert(utf8.encode(hash)).toString();
    return hash == package.hash && signature == package.signature;
  }
}
