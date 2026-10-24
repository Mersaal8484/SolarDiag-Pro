import 'package:flutter/foundation.dart';

import 'profile_integrity.dart';

enum TrustAnchorPurpose { development, production, placeholder }

class TrustAnchorKey {
  const TrustAnchorKey({
    required this.keyId,
    required this.publicKeyBytes,
    required this.notBefore,
    required this.notAfter,
    this.purpose = TrustAnchorPurpose.production,
  });

  final String keyId;
  final List<int> publicKeyBytes;
  final DateTime notBefore;
  final DateTime notAfter;
  final TrustAnchorPurpose purpose;

  bool isValidAt(DateTime now) {
    return _isValidAt(now, releaseMode: kReleaseMode);
  }

  bool _isValidAt(DateTime now, {required bool releaseMode}) {
    if (purpose == TrustAnchorPurpose.placeholder) return false;
    if (purpose == TrustAnchorPurpose.development) {
      if (releaseMode ||
          !const bool.fromEnvironment('ALLOW_DEV_TRUST', defaultValue: false)) {
        return false;
      }
    }
    return !now.isBefore(notBefore) && !now.isAfter(notAfter);
  }

  Ed25519TrustVerifier createVerifier() => Ed25519TrustVerifier(publicKeyBytes);
}

class TrustAnchorRegistry {
  TrustAnchorRegistry([List<TrustAnchorKey>? keys])
    : keys = List.unmodifiable(keys ?? defaultAnchors);

  final List<TrustAnchorKey> keys;

  /// Bootstrap placeholders only.  They are intentionally invalid for
  /// verification until a release process installs documented production
  /// anchors.  This prevents arbitrary bytes from being represented as real
  /// production trust roots.
  static final List<TrustAnchorKey> defaultAnchors = [
    TrustAnchorKey(
      keyId: 'solardiag-root-2026-v1',
      publicKeyBytes: const [
        0x3b,
        0x6a,
        0x27,
        0xbc,
        0xce,
        0xb6,
        0xa4,
        0x2d,
        0x62,
        0xa3,
        0xa8,
        0xd0,
        0x2a,
        0x6f,
        0x0d,
        0x73,
        0x65,
        0x32,
        0x15,
        0x77,
        0x1d,
        0xe2,
        0x43,
        0xa6,
        0x3a,
        0xc0,
        0x48,
        0xa1,
        0x8b,
        0x59,
        0xda,
        0x29,
      ],
      notBefore: DateTime.utc(2026, 1, 1),
      notAfter: DateTime.utc(2028, 1, 1),
      purpose: TrustAnchorPurpose.placeholder,
    ),
    TrustAnchorKey(
      keyId: 'solardiag-root-2026-v2',
      publicKeyBytes: const [
        0x7c,
        0x89,
        0xd2,
        0x14,
        0xa5,
        0x3e,
        0x9f,
        0x61,
        0x45,
        0x23,
        0x88,
        0xcc,
        0x5b,
        0x12,
        0xee,
        0x90,
        0x44,
        0x11,
        0x76,
        0xbb,
        0x33,
        0x99,
        0xaa,
        0x10,
        0x20,
        0x30,
        0x40,
        0x50,
        0x60,
        0x70,
        0x80,
        0x90,
      ],
      notBefore: DateTime.utc(2026, 6, 1),
      notAfter: DateTime.utc(2029, 1, 1),
      purpose: TrustAnchorPurpose.placeholder,
    ),
  ];

  TrustAnchorKey? findKey(String keyId, {DateTime? now}) {
    final check = now ?? DateTime.now().toUtc();
    return keys
        .where((key) => key.keyId == keyId && key.isValidAt(check))
        .firstOrNull;
  }

  @visibleForTesting
  TrustAnchorKey? findKeyForBuild(
    String keyId, {
    required DateTime now,
    required bool releaseMode,
  }) => keys
      .where(
        (key) =>
            key.keyId == keyId && key._isValidAt(now, releaseMode: releaseMode),
      )
      .firstOrNull;

  Ed25519TrustVerifier? verifierFor(String keyId, {DateTime? now}) =>
      findKey(keyId, now: now)?.createVerifier();
}
