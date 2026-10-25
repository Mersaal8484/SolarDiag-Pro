import 'dart:convert';
import 'dart:io';

import '../protocol/capabilities.dart';
import '../protocol/profile_registry.dart';
import 'library_write_reason.dart';
import 'profile_integrity.dart';

enum LibraryChannel { beta, stable }

class LibraryDeliveryMetadata {
  const LibraryDeliveryMetadata({
    required this.channel,
    this.deltaFromVersion,
    this.retainedPreviousVersion,
  });

  final LibraryChannel channel;
  final int? deltaFromVersion;
  final int? retainedPreviousVersion;

  bool get isDelta => deltaFromVersion != null;

  Map<String, Object?> toJson() => {
    'channel': channel.name,
    if (deltaFromVersion != null) 'delta_from_version': deltaFromVersion,
    if (retainedPreviousVersion != null)
      'retained_previous_version': retainedPreviousVersion,
  };

  factory LibraryDeliveryMetadata.fromJson(Map<String, Object?> json) {
    final channelName = _string(json, 'channel');
    final channel = LibraryChannel.values.where(
      (candidate) => candidate.name == channelName,
    );
    if (channel.length != 1) {
      throw FormatException('Unsupported library channel: $channelName.');
    }
    final delta = json['delta_from_version'];
    final previous = json['retained_previous_version'];
    if ((delta != null && delta is! int) ||
        (previous != null && previous is! int)) {
      throw const FormatException('Invalid library delivery version metadata.');
    }
    return LibraryDeliveryMetadata(
      channel: channel.single,
      deltaFromVersion: delta as int?,
      retainedPreviousVersion: previous as int?,
    );
  }
}

class LibraryPack {
  const LibraryPack({
    required this.id,
    required this.version,
    required this.minAppVersion,
    required this.expiresAt,
    required this.profileHashes,
    required this.profiles,
    required this.signature,
    this.delivery,
  });
  final String id;
  final int version;
  final int minAppVersion;
  final DateTime expiresAt;
  final Map<String, String> profileHashes;
  final Map<String, SignedProfileDocument> profiles;
  final String signature;
  final LibraryDeliveryMetadata? delivery;
  Map<String, Object?> get payload {
    final deliveryJson = delivery?.toJson();
    return {
      'id': id,
      'version': version,
      'min_app_version': minAppVersion,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'profile_hashes': profileHashes,
      if (deliveryJson != null) 'delivery': deliveryJson,
    };
  }

  Map<String, Object?> toJson() => {
    ...payload,
    'profiles': profiles.map((key, value) => MapEntry(key, value.toJson())),
    'signature': signature,
  };

  factory LibraryPack.fromJson(Map<String, Object?> json) {
    final hashes = json['profile_hashes'];
    final documents = json['profiles'];
    final deliveryJson = json['delivery'];
    if (hashes is! Map || documents is! Map) {
      throw const FormatException('Invalid library pack profile maps.');
    }
    Map<String, Object?>? parsedDelivery;
    if (deliveryJson != null) {
      if (deliveryJson is! Map) {
        throw const FormatException('Invalid library delivery metadata.');
      }
      parsedDelivery = Map<String, Object?>.from(deliveryJson);
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
      delivery: parsedDelivery == null
          ? null
          : LibraryDeliveryMetadata.fromJson(parsedDelivery),
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

  Map<String, Object?> toJson() => {...payload, 'signature': signature};

  factory RevocationList.fromJson(Map<String, Object?> json) {
    Set<String> identifiers(String key) {
      final value = json[key];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('$key must be a list of strings.');
      }
      return Set.unmodifiable(value.cast<String>());
    }

    final sequence = json['sequence'];
    final issuedAt = json['issued_at'];
    final validUntil = json['valid_until'];
    final signature = json['signature'];
    if (sequence is! int ||
        issuedAt is! String ||
        validUntil is! String ||
        signature is! String) {
      throw const FormatException('Invalid stored revocation list.');
    }
    return RevocationList(
      sequence: sequence,
      issuedAt: DateTime.parse(issuedAt),
      validUntil: DateTime.parse(validUntil),
      revokedPackIds: identifiers('revoked_packs'),
      revokedProfileIds: identifiers('revoked_profiles'),
      signature: signature,
    );
  }
}

abstract interface class LibraryPackStore {
  Future<void> save(LibraryPack pack);
  Future<LibraryPack?> load();
  Future<void> saveRevocations(RevocationList revocations);
  Future<RevocationList?> loadRevocations();
  Future<int> loadHighestRevocationSequence();
  Future<void> saveHighestRevocationSequence(int sequence);
}

abstract interface class RetainedLibraryPackStore implements LibraryPackStore {
  Future<void> savePrevious(LibraryPack pack);
  Future<LibraryPack?> loadPrevious();
}

class FileLibraryPackStore implements RetainedLibraryPackStore {
  const FileLibraryPackStore(this.path);
  final String path;
  String get _seqPath => '$path.revseq';
  String get _revocationsPath => '$path.revocations';
  String get _previousPath => '$path.previous';

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

  @override
  Future<LibraryPack?> loadPrevious() async {
    final file = File(_previousPath);
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Stored previous library pack is not an object.',
      );
    }
    return LibraryPack.fromJson(decoded);
  }

  @override
  Future<void> savePrevious(LibraryPack pack) async {
    final target = File(_previousPath);
    await target.parent.create(recursive: true);
    final temporary = File('$_previousPath.tmp');
    await temporary.writeAsString(jsonEncode(pack.toJson()), flush: true);
    await temporary.rename(_previousPath);
  }

  @override
  Future<RevocationList?> loadRevocations() async {
    final file = File(_revocationsPath);
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Stored revocation list is not an object.');
    }
    return RevocationList.fromJson(decoded);
  }

  @override
  Future<void> saveRevocations(RevocationList revocations) async {
    final target = File(_revocationsPath);
    await target.parent.create(recursive: true);
    final temporary = File('$_revocationsPath.tmp');
    await temporary.writeAsString(
      jsonEncode(revocations.toJson()),
      flush: true,
    );
    await temporary.rename(_revocationsPath);
  }

  @override
  Future<int> loadHighestRevocationSequence() async {
    final file = File(_seqPath);
    if (!await file.exists()) return 0;
    try {
      return int.parse((await file.readAsString()).trim());
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> saveHighestRevocationSequence(int sequence) async {
    final target = File(_seqPath);
    await target.parent.create(recursive: true);
    final temporary = File('$_seqPath.tmp');
    await temporary.writeAsString('$sequence', flush: true);
    await temporary.rename(_seqPath);
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
  bool get isRevocationExpired =>
      _clock().toUtc().isAfter(revocations.validUntil);

  bool blocksWritesFor(String profileId) =>
      writeDisabledReasonFor(profileId) != null;

  LibraryWriteDisabledReason? get writeDisabledReason {
    if (packRevoked) return LibraryWriteDisabledReason.revoked;
    if (isRevocationExpired) {
      return LibraryWriteDisabledReason.revocationListExpired;
    }
    if (isRevocationStale) return LibraryWriteDisabledReason.stale;
    return null;
  }

  LibraryWriteDisabledReason? writeDisabledReasonFor(String profileId) =>
      writeDisabledReason ??
      (revokedProfileIds.contains(profileId)
          ? LibraryWriteDisabledReason.revoked
          : null);

  bool profileCanWrite(
    String profileId, [
    DeviceCapability capability = DeviceCapability.writeParameter,
  ]) {
    if (blocksWritesFor(profileId)) return false;
    return registry.profileCanWrite(profileId, capability);
  }

  bool get showRevokedBanner =>
      packRevoked ||
      revokedProfileIds.isNotEmpty ||
      isRevocationStale ||
      isRevocationExpired;
}

class LibrarySync {
  LibrarySync({
    required this.verifier,
    required this.appVersion,
    required this.store,
    this.maxRevocationAge = const Duration(days: 14),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _revocationState = store.loadHighestRevocationSequence();

  final Ed25519TrustVerifier verifier;
  final int appVersion;
  final LibraryPackStore store;
  final Duration maxRevocationAge;
  final DateTime Function() _clock;
  InstalledLibrary? _installed;
  LibraryPack? _previousKnownGood;
  int _highestRevocationSequence = 0;
  final Future<int> _revocationState;

  InstalledLibrary? get installed => _installed;
  LibraryPack? get lastKnownGood => _installed?.pack;
  LibraryPack? get previousKnownGood => _previousKnownGood;
  int get highestRevocationSequence => _highestRevocationSequence;
  LibraryWriteDisabledReason? writeDisabledReasonFor(String profileId) =>
      _installed?.writeDisabledReasonFor(profileId) ??
      (_installed == null ? LibraryWriteDisabledReason.libraryMissing : null);

  /// Loads the persisted anti-rollback floor before any asynchronous library
  /// operation.  The previous fire-and-forget initialization allowed a pack
  /// to be evaluated before that floor had arrived from storage.
  Future<void> _ensureRevocationState() async {
    final persisted = await _revocationState;
    if (persisted > _highestRevocationSequence) {
      _highestRevocationSequence = persisted;
    }
  }

  Future<void> recordRevocationSequence(int sequence) async {
    if (_highestRevocationSequence > 0 &&
        sequence < _highestRevocationSequence) {
      throw StateError(
        'Revocation list sequence rollback: $sequence < $_highestRevocationSequence',
      );
    }
    _highestRevocationSequence = sequence;
    await store.saveHighestRevocationSequence(sequence);
  }

  Future<bool> apply(
    LibraryPack pack, {
    required DateTime now,
    required RevocationList revocations,
  }) =>
      _apply(pack, now: now, revocations: revocations, allowRevokedPack: false);

  Future<bool> _apply(
    LibraryPack pack, {
    required DateTime now,
    required RevocationList revocations,
    required bool allowRevokedPack,
    bool restoringStoredPack = false,
  }) async {
    await _ensureRevocationState();
    if (!await verifier.verifyPayload(
          revocations.payload,
          revocations.signature,
        ) ||
        !await verifier.verifyPayload(pack.payload, pack.signature)) {
      return false;
    }
    if (_highestRevocationSequence > 0 &&
        revocations.sequence < _highestRevocationSequence) {
      return false;
    }
    final hashKeys = pack.profileHashes.keys.toSet();
    final profileKeys = pack.profiles.keys.toSet();
    final packRevoked = revocations.revokedPackIds.contains(pack.id);
    final delivery = pack.delivery;
    final currentVersion = _installed?.pack.version;
    if ((packRevoked && !allowRevokedPack) ||
        pack.expiresAt.isBefore(now) ||
        pack.minAppVersion > appVersion ||
        (_installed != null && pack.version <= _installed!.pack.version) ||
        hashKeys.difference(profileKeys).isNotEmpty ||
        profileKeys.difference(hashKeys).isNotEmpty) {
      return false;
    }
    if (!restoringStoredPack &&
        delivery != null &&
        ((delivery.deltaFromVersion != null &&
                delivery.deltaFromVersion != currentVersion) ||
            (delivery.retainedPreviousVersion != null &&
                delivery.retainedPreviousVersion != currentVersion))) {
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
    final previous = _installed?.pack;
    final retainedStore = store;
    if (!restoringStoredPack &&
        previous != null &&
        retainedStore is RetainedLibraryPackStore) {
      await retainedStore.savePrevious(previous);
      _previousKnownGood = previous;
    }
    await store.saveRevocations(revocations);
    await store.save(pack);
    _highestRevocationSequence = revocations.sequence;
    await store.saveHighestRevocationSequence(_highestRevocationSequence);
    _installed = InstalledLibrary(
      pack: pack,
      registry: registry,
      revokedProfileIds: Set.unmodifiable(revocations.revokedProfileIds),
      packRevoked: packRevoked,
      revocations: revocations,
      maxRevocationAge: maxRevocationAge,
      clock: _clock,
    );
    return true;
  }

  Future<bool> restoreOffline({
    required DateTime now,
    RevocationList? revocations,
  }) async {
    await _ensureRevocationState();
    final pack = await store.load();
    final persistedRevocations = revocations ?? await store.loadRevocations();
    if (pack == null || persistedRevocations == null) return false;
    _installed = null;
    return _apply(
      pack,
      now: now,
      revocations: persistedRevocations,
      allowRevokedPack: true,
      restoringStoredPack: true,
    );
  }

  Future<LibraryPack?> loadRetainedPrevious() async {
    final retainedStore = store;
    if (retainedStore is! RetainedLibraryPackStore) return null;
    _previousKnownGood = await retainedStore.loadPrevious();
    return _previousKnownGood;
  }

  Future<bool> refreshRevocations(RevocationList revocations) async {
    await _ensureRevocationState();
    if (!await verifier.verifyPayload(
      revocations.payload,
      revocations.signature,
    )) {
      return false;
    }
    if (revocations.sequence < _highestRevocationSequence) {
      return false;
    }
    final current = _installed;
    if (revocations.sequence == _highestRevocationSequence) {
      // Replaying the exact list is harmless and must not turn a transient
      // refresh retry into a failure.  A different payload at the same
      // sequence is rejected to avoid equivocation.
      if (current == null ||
          jsonEncode(current.revocations.payload) !=
              jsonEncode(revocations.payload) ||
          current.revocations.signature != revocations.signature) {
        return false;
      }
      return true;
    }
    _highestRevocationSequence = revocations.sequence;
    await store.saveHighestRevocationSequence(_highestRevocationSequence);
    await store.saveRevocations(revocations);
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
