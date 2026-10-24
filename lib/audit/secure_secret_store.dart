import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'audit_chain.dart';

/// Platform-backed store for audit HMAC keys.
///
/// The audit chain is synchronous by design, so this store must be initialized
/// before a session is created. It never falls back to a file, database, or
/// deterministic value: an unavailable platform keystore leaves the session
/// write-locked.
class SecureSecretStore implements SecretStore {
  SecureSecretStore._(this._storage);

  static const installationAuditKey = 'installation_audit_key';

  final FlutterSecureStorage _storage;
  final Map<String, List<int>> _cache = {};

  static Future<SecureSecretStore> initialize({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    String keyId = installationAuditKey,
  }) async {
    final store = SecureSecretStore._(storage);
    await store.getOrCreateSecret(keyId);
    return store;
  }

  @override
  Future<List<int>> getOrCreateSecret(String keyId) async {
    final cached = _cache[keyId];
    if (cached != null) return List<int>.unmodifiable(cached);

    final encoded = await _storage.read(key: keyId);
    if (encoded != null) {
      final decoded = base64Url.decode(encoded);
      if (decoded.length < 32) {
        throw StateError('Secure audit secret has an invalid length.');
      }
      _cache[keyId] = List<int>.unmodifiable(decoded);
      return List<int>.unmodifiable(decoded);
    }

    final random = Random.secure();
    final secret = List<int>.generate(32, (_) => random.nextInt(256));
    await _storage.write(key: keyId, value: base64Url.encode(secret));
    _cache[keyId] = List<int>.unmodifiable(secret);
    return List<int>.unmodifiable(secret);
  }

  @override
  List<int> getOrCreateSecretSync(String keyId) {
    final secret = _cache[keyId];
    if (secret == null) {
      throw StateError('Secure audit secret is not initialized.');
    }
    return secret;
  }
}
