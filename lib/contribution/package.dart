import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'consent.dart';
import 'redaction.dart';

class ContributionData {
  const ContributionData({
    this.logs,
    this.samples,
    this.notes,
    this.deviceIdentity = const {},
  });

  final String? logs;
  final String? samples;
  final String? notes;
  final Map<String, String> deviceIdentity;
}

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
    required ContributionData data,
    required String pseudonymousContributorId,
    required ContributionConsent consent,
    required bool synthetic,
    required String sessionSalt,
    required List<int> installationKey,
    Iterable<String> denyList = const [],
  }) {
    if (synthetic) {
      throw StateError('Synthetic or simulated data cannot be submitted.');
    }
    if (!consent.isValid) {
      throw StateError('A valid granular consent record is required.');
    }
    final source = <String, Object?>{
      if (consent.logs && data.logs != null) 'logs': data.logs,
      if (consent.samples && data.samples != null) 'samples': data.samples,
      if (consent.notes && data.notes != null) 'notes': data.notes,
      if (consent.deviceIdentity && data.deviceIdentity.isNotEmpty)
        'device_identity': data.deviceIdentity,
    };
    if (source.isEmpty) {
      throw StateError('No consented contribution categories contain data.');
    }

    final changes = <RedactionChange>[];
    String redactValue(String value) {
      final result = const ContributionRedactor().redact(
        value,
        sessionSalt: sessionSalt,
        denyList: denyList,
      );
      if (result.manualReviewRequired) {
        throw StateError(
          'Manual review required: ${result.remainingDetections.join(', ')}',
        );
      }
      changes.addAll(result.changes);
      return result.redacted;
    }

    final packaged = <String, Object?>{};
    for (final entry in source.entries) {
      final value = entry.value;
      packaged[entry.key] = value is Map<String, String>
          ? value.map((key, item) => MapEntry(key, redactValue(item)))
          : redactValue(value! as String);
    }
    final sharedCategories = packaged.keys.toList()..sort();
    final manifest = <String, Object?>{
      'schema_version': 2,
      'contributor_id': pseudonymousContributorId,
      'synthetic': false,
      'what_will_be_shared': sharedCategories,
      'consent': {
        'granted_at': consent.grantedAt.toUtc().toIso8601String(),
        'version': consent.consentVersion,
      },
      'redaction_report': {
        'changes': changes.length,
        'kinds': changes.map((item) => item.kind).toSet().toList()..sort(),
        'legal_review_required': true,
      },
    };
    final payload = jsonEncode(packaged);
    final content = '${jsonEncode(manifest)}|$payload';
    final hash = sha256.convert(utf8.encode(content)).toString();
    final signature = Hmac(
      sha256,
      installationKey,
    ).convert(utf8.encode(hash)).toString();
    return ContributionPackage(
      manifest: Map.unmodifiable(manifest),
      payload: payload,
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
