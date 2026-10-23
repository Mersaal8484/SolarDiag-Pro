import 'dart:convert';
import 'dart:io';

import '../protocol/capabilities.dart';
import '../protocol/profile_registry.dart';
import 'profile_integrity.dart';

class LibraryPack {
  const LibraryPack({
    required this.id,
    required this.version,
    required this.minAppVersion,
    required this.expiresAt,
    required this.profileHashes,
    required this.profiles,
    required this.signature,
  });
  final String id;
  final int version;
  final int minAppVersion;
  final DateTime expiresAt;
  final Map<String, String> profileHashes;
  final Map<String, SignedProfileDocument> profiles;
  final String signature;
  Map<String, Object?> get payload => {
    'id': id,
    'version': version,
    'min_app_version': minAppVersion,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'profile_hashes': profileHashes,
  };
  Map<String, Object?> toJson() => {
    ...payload,
    'profiles': profiles.map((key, value) => MapEntry(key, value.toJson())),
    'signature': signature,
  };

  factory LibraryPack.fromJson(Map<String, Object?> json) {
    final hashes = json['profile_hashes'];
    final documents = json['profiles'];
    if (hashes is! Map || documents is! Map) {
      throw const FormatException('Invalid library pack profile maps.');
    }
    return LibraryPack(
      id: _string(json, 'id'),
      version: _integer(json, 'version'),
      minAppVersion: _integer(json, 'min_app_version'),
      expiresAt: DateTime.parse(_string(json, 'expires_at')),
      profileHashes: hashes.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      profiles: documents.map(
        (key, value) => MapEntry(
          key.toString(),
          SignedProfileDocument.fromJson(
            Map<String, Object?>.from(value as Map),
          ),
        ),
      ),
      signature: _string(json, 'signature'),
    );
  }
}

class RevocationList {
  RevocationList({
    this.sequence = 1,
    DateTime? issuedAt,
    DateTime? validUntil,
    this.revokedPackIds = const {},
    this.revokedProfileIds = const {},
    this.signature = '',
  }) : issuedAt = issuedAt ?? DateTime.utc(2026, 1, 1),
       validUntil = validUntil ?? DateTime.utc(2026, 12, 31);

  final int sequence;
  final DateTime issuedAt;
  final DateTime validUntil;
  final Set<String> revokedPackIds;
  final Set<String> revokedProfileIds;
  final String signature;

  Map<String, Object?> get payload => {
    'sequence': sequence,
    'issued_at': issuedAt.toUtc().toIso8601String(),
    'valid_until': validUntil.toUtc().toIso8601String(),
    'revoked_packs': revokedPackIds.toList()..sort(),
    'revoked_profiles': revokedProfileIds.toList()..sort(),
  };
}

abstract interface class LibraryPackStore {
  Future<void> save(LibraryPack pack);
  Future<LibraryPack?> load();
}

class FileLibraryPackStore implements LibraryPackStore {
  const FileLibraryPackStore(this.path);
  final String path;
  @override
  Future<LibraryPack?> load() async {
    final file = File(path);
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Stored library pack is not an object.');
    }
    return LibraryPack.fromJson(decoded);
  }

  @override
  Future<void> save(LibraryPack pack) async {
    final target = File(path);
    await target.parent.create(recursive: true);
    final temporary = File('$path.tmp');
    await temporary.writeAsString(jsonEncode(pack.toJson()), flush: true);
    await temporary.rename(path);
  }
}

class InstalledLibrary {
  const InstalledLibrary({
    required this.pack,
    required this.registry,
    required this.revokedProfileIds,
    required this.packRevoked,
    required this.revocations,
    required this.maxRevocationAge,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LibraryPack pack;
  final ProfileRegistry registry;
  final Set<String> revokedProfileIds;
  final bool packRevoked;
  final RevocationList revocations;
  final Duration maxRevocationAge;
  final DateTime Function() _clock;

  bool get isRevocationStale =>
      _clock().toUtc().difference(revocations.issuedAt) > maxRevocationAge;

  String? get writeDisabledReason {
    if (packRevoked) return 'Library pack is revoked.';
    if (isRevocationStale) return 'revocation data stale';
    return null;
  }

  bool profileCanWrite(
    String profileId, [
    DeviceCapability capability = DeviceCapability.writeParameter,
  ]) {
    if (packRevoked || isRevocationStale) return false;
    if (revokedProfileIds.contains(profileId)) return false;
    return registry.profileCanWrite(profileId, capability);
  }

  bool get showRevokedBanner =>
      packRevoked || revokedProfileIds.isNotEmpty || isRevocationStale;
}

class LibrarySync {
  LibrarySync({
    required this.verifier,
    required this.appVersion,
    required this.store,
    this.maxRevocationAge = const Duration(days: 14),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Ed25519TrustVerifier verifier;
  final int appVersion;
  final LibraryPackStore store;
  final Duration maxRevocationAge;
  final DateTime Function() _clock;
  InstalledLibrary? _installed;
  int _highestRevocationSequence = 0;

  InstalledLibrary? get installed => _installed;
  LibraryPack? get lastKnownGood => _installed?.pack;
  int get highestRevocationSequence => _highestRevocationSequence;

  void recordRevocationSequence(int sequence) {
    if (_highestRevocationSequence > 0 &&
        sequence <= _highestRevocationSequence) {
      throw StateError(
        'Revocation list sequence rollback: $sequence <= $_highestRevocationSequence',
      );
    }
    _highestRevocationSequence = sequence;
  }

  Future<bool> apply(
    LibraryPack pack, {
    required DateTime now,
    required RevocationList revocations,
  }) async {
    if (!await verifier.verifyPayload(
          revocations.payload,
          revocations.signature,
        ) ||
        !await verifier.verifyPayload(pack.payload, pack.signature)) {
      return false;
    }
    if (_highestRevocationSequence > 0 &&
        revocations.sequence <= _highestRevocationSequence) {
      return false;
    }
    final hashKeys = pack.profileHashes.keys.toSet();
    final profileKeys = pack.profiles.keys.toSet();
    if (revocations.revokedPackIds.contains(pack.id) ||
        pack.expiresAt.isBefore(now) ||
        pack.minAppVersion > appVersion ||
        (_installed != null && pack.version <= _installed!.pack.version) ||
        hashKeys.difference(profileKeys).isNotEmpty ||
        profileKeys.difference(hashKeys).isNotEmpty) {
      return false;
    }
    for (final entry in pack.profiles.entries) {
      final signed = entry.value;
      if (pack.profileHashes[entry.key] != signed.contentHash ||
          !await verifier.verifyProfile(signed)) {
        return false;
      }
    }
    final registry = await ProfileRegistry.fromSignedDocuments(
      pack.profiles.values,
      verifier: verifier,
      technicianMode: true,
    );
    await store.save(pack);
    _highestRevocationSequence = revocations.sequence;
    _installed = InstalledLibrary(
      pack: pack,
      registry: registry,
      revokedProfileIds: Set.unmodifiable(revocations.revokedProfileIds),
      packRevoked: false,
      revocations: revocations,
      maxRevocationAge: maxRevocationAge,
      clock: _clock,
    );
    return true;
  }

  Future<bool> restoreOffline({
    required DateTime now,
    required RevocationList revocations,
  }) async {
    final pack = await store.load();
    if (pack == null) return false;
    _installed = null;
    return apply(pack, now: now, revocations: revocations);
  }

  Future<bool> refreshRevocations(RevocationList revocations) async {
    if (!await verifier.verifyPayload(
      revocations.payload,
      revocations.signature,
    )) {
      return false;
    }
    if (revocations.sequence <= _highestRevocationSequence) {
      return false;
    }
    _highestRevocationSequence = revocations.sequence;
    final current = _installed;
    if (current == null) return true;
    _installed = InstalledLibrary(
      pack: current.pack,
      registry: current.registry,
      revokedProfileIds: Set.unmodifiable(revocations.revokedProfileIds),
      packRevoked: revocations.revokedPackIds.contains(current.pack.id),
      revocations: revocations,
      maxRevocationAge: maxRevocationAge,
      clock: _clock,
    );
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
  const EntitlementValidator(this.verifier);
  final Ed25519TrustVerifier verifier;
  Future<bool> permits(
    EntitlementToken token,
    String feature,
    DateTime now,
  ) async =>
      await verifier.verifyPayload(token.payload, token.signature) &&
      !token.expiresAt.isBefore(now) &&
      token.features.contains(feature);
  bool safetyInformationVisible(String feature) => const {
    'active_alarms',
    'protection_states',
    'safety_warnings',
    'read_only_monitoring',
  }.contains(feature);
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}
