import 'dart:convert';
import 'package:crypto/crypto.dart';

class MockSigner {
  const MockSigner(this.key);
  final List<int> key;
  String sign(Map<String, Object?> payload) =>
      Hmac(sha256, key).convert(utf8.encode(_canonical(payload))).toString();
  bool verify(Map<String, Object?> payload, String signature) =>
      sign(payload) == signature;
  static String _canonical(Map<String, Object?> payload) {
    final keys = payload.keys.toList()..sort();
    return jsonEncode({for (final key in keys) key: payload[key]});
  }
}

class LibraryPack {
  const LibraryPack({
    required this.id,
    required this.version,
    required this.minAppVersion,
    required this.expiresAt,
    required this.profileHashes,
    required this.signature,
  });
  final String id;
  final int version;
  final int minAppVersion;
  final DateTime expiresAt;
  final Map<String, String> profileHashes;
  final String signature;
  Map<String, Object?> get payload => {
    'id': id,
    'version': version,
    'min_app_version': minAppVersion,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'profile_hashes': profileHashes,
  };
}

class RevocationList {
  const RevocationList({required this.revokedPackIds, required this.signature});
  final Set<String> revokedPackIds;
  final String signature;
  Map<String, Object?> get payload => {
    'revoked': revokedPackIds.toList()..sort(),
  };
}

class LibrarySync {
  LibrarySync({required this.signer, required this.appVersion});
  final MockSigner signer;
  final int appVersion;
  LibraryPack? _lastKnownGood;
  LibraryPack? get lastKnownGood => _lastKnownGood;
  bool apply(
    LibraryPack pack, {
    required DateTime now,
    required RevocationList revocations,
  }) {
    if (!signer.verify(revocations.payload, revocations.signature)) {
      return false;
    }
    if (!signer.verify(pack.payload, pack.signature)) return false;
    if (revocations.revokedPackIds.contains(pack.id) ||
        pack.expiresAt.isBefore(now) ||
        pack.minAppVersion > appVersion ||
        (_lastKnownGood != null && pack.version <= _lastKnownGood!.version)) {
      return false;
    }
    _lastKnownGood = pack;
    return true;
  }
}

class EntitlementToken {
  const EntitlementToken({
    required this.subject,
    required this.features,
    required this.expiresAt,
    required this.signature,
  });
  final String subject;
  final Set<String> features;
  final DateTime expiresAt;
  final String signature;
  Map<String, Object?> get payload => {
    'subject': subject,
    'features': features.toList()..sort(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };
}

class EntitlementValidator {
  const EntitlementValidator(this.signer);
  final MockSigner signer;
  bool permits(EntitlementToken token, String feature, DateTime now) =>
      signer.verify(token.payload, token.signature) &&
      !token.expiresAt.isBefore(now) &&
      token.features.contains(feature);
  bool safetyInformationVisible(String feature) => const {
    'active_alarms',
    'protection_states',
    'safety_warnings',
    'read_only_monitoring',
  }.contains(feature);
}
