import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

String canonicalJson(Object? value) {
  Object? normalize(Object? item) {
    if (item is Map) {
      final keys = item.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: normalize(item[key]),
      };
    }
    if (item is List) return item.map(normalize).toList();
    return item;
  }

  return jsonEncode(normalize(value));
}

String sha256Hex(String bytes) => sha256.convert(utf8.encode(bytes)).toString();

class SignedProfileDocument {
  const SignedProfileDocument({
    required this.document,
    required this.contentHash,
    required this.signature,
  });

  final String document;
  final String contentHash;
  final String signature;

  Map<String, Object?> toJson() => {
    'document': document,
    'content_hash': contentHash,
    'signature': signature,
  };

  factory SignedProfileDocument.fromJson(Map<String, Object?> json) {
    String field(String name) {
      final value = json[name];
      if (value is! String || value.isEmpty) {
        throw FormatException('$name must be a non-empty string.');
      }
      return value;
    }

    return SignedProfileDocument(
      document: field('document'),
      contentHash: field('content_hash'),
      signature: field('signature'),
    );
  }
}

class Ed25519TrustVerifier {
  Ed25519TrustVerifier(List<int> publicKeyBytes)
    : _publicKey = SimplePublicKey(
        List<int>.unmodifiable(publicKeyBytes),
        type: KeyPairType.ed25519,
      ) {
    if (publicKeyBytes.length != 32) {
      throw ArgumentError.value(publicKeyBytes.length, 'publicKeyBytes');
    }
  }

  final SimplePublicKey _publicKey;
  final Ed25519 _algorithm = Ed25519();

  Future<bool> verifyBytes(List<int> bytes, String signature) async {
    late final List<int> signatureBytes;
    try {
      signatureBytes = base64Decode(signature);
    } on FormatException {
      return false;
    }
    if (signatureBytes.length != 64) return false;
    return _algorithm.verify(
      bytes,
      signature: Signature(signatureBytes, publicKey: _publicKey),
    );
  }

  Future<bool> verifyPayload(Map<String, Object?> payload, String signature) =>
      verifyBytes(utf8.encode(canonicalJson(payload)), signature);

  Future<bool> verifyProfile(SignedProfileDocument profile) async {
    final actualHash = sha256Hex(profile.document);
    if (!_constantTimeEquals(actualHash, profile.contentHash)) return false;
    return verifyBytes(utf8.encode(profile.document), profile.signature);
  }

  static bool _constantTimeEquals(String left, String right) {
    final a = utf8.encode(left);
    final b = utf8.encode(right);
    var difference = a.length ^ b.length;
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final leftByte = index < a.length ? a[index] : 0;
      final rightByte = index < b.length ? b[index] : 0;
      difference |= leftByte ^ rightByte;
    }
    return difference == 0;
  }
}
