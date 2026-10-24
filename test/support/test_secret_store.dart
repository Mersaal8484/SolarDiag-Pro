import 'dart:math';

import 'package:solardiag_pro/audit/audit_chain.dart';

class TestSecretStore implements SecretStore {
  final Map<String, List<int>> _secrets = {};

  @override
  Future<List<int>> getOrCreateSecret(String keyId) async =>
      getOrCreateSecretSync(keyId);

  @override
  List<int> getOrCreateSecretSync(String keyId) =>
      _secrets.putIfAbsent(keyId, () {
        final random = Random.secure();
        return List<int>.generate(32, (_) => random.nextInt(256));
      });
}
