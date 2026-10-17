import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';

class TestSigner {
  TestSigner._(this._keyPair, this.publicKeyBytes);

  final SimpleKeyPair _keyPair;
  final List<int> publicKeyBytes;
  final Ed25519 _algorithm = Ed25519();

  static Future<TestSigner> create(int seed) async {
    final bytes = List<int>.generate(32, (index) => (seed + index) & 0xff);
    final algorithm = Ed25519();
    final pair = await algorithm.newKeyPairFromSeed(bytes);
    final publicKey = await pair.extractPublicKey();
    return TestSigner._(pair, publicKey.bytes);
  }

  Future<String> signBytes(List<int> bytes) async {
    final signature = await _algorithm.sign(bytes, keyPair: _keyPair);
    return base64Encode(signature.bytes);
  }

  Future<String> signPayload(Map<String, Object?> payload) =>
      signBytes(utf8.encode(canonicalJson(payload)));

  Future<SignedProfileDocument> signProfile(String document) async =>
      SignedProfileDocument(
        document: document,
        contentHash: sha256Hex(document),
        signature: await signBytes(utf8.encode(document)),
      );
}
