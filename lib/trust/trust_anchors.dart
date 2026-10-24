import 'profile_integrity.dart';

enum TrustAnchorPurpose { development, production }

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

  bool isValidAt(DateTime now, {bool allowDevelopmentAnchors = false}) {
    if (purpose == TrustAnchorPurpose.development && !allowDevelopmentAnchors) {
      return false;
    }
    return !now.isBefore(notBefore) && !now.isAfter(notAfter);
  }

  Ed25519TrustVerifier createVerifier() => Ed25519TrustVerifier(publicKeyBytes);
}

class TrustAnchorRegistry {
  TrustAnchorRegistry([
    List<TrustAnchorKey>? keys,
    bool? allowDevelopmentAnchors,
  ]) : keys = List.unmodifiable(keys ?? defaultAnchors),
       allowDevelopmentAnchors =
           allowDevelopmentAnchors ??
           const bool.fromEnvironment('ALLOW_DEV_TRUST', defaultValue: false);

  factory TrustAnchorRegistry.withOptions({
    List<TrustAnchorKey>? keys,
    bool allowDevelopmentAnchors = false,
  }) => TrustAnchorRegistry(keys, allowDevelopmentAnchors);

  final List<TrustAnchorKey> keys;
  final bool allowDevelopmentAnchors;

  /// Default production trust anchors embedded at compile-time.
  /// No private key is ever stored or shipped in this repository.
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
    ),
  ];

  TrustAnchorKey? findKey(String keyId, {DateTime? now}) {
    final check = now ?? DateTime.now().toUtc();
    return keys
        .where(
          (key) =>
              key.keyId == keyId &&
              key.isValidAt(
                check,
                allowDevelopmentAnchors: allowDevelopmentAnchors,
              ),
        )
        .firstOrNull;
  }

  Ed25519TrustVerifier? verifierFor(String keyId, {DateTime? now}) =>
      findKey(keyId, now: now)?.createVerifier();
}
