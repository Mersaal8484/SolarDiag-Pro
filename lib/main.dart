import 'package:flutter/material.dart';

import 'app/solardiag_app.dart';
import 'audit/audit_chain.dart';
import 'audit/secure_secret_store.dart';
import 'persistence/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await LocalDatabase.openDefault();
  SecretStore? auditSecretStore;
  try {
    auditSecretStore = await SecureSecretStore.initialize();
  } catch (_) {
    // No fallback is permitted. DeviceSession keeps writes locked when the
    // platform-backed audit secret cannot be initialized.
  }
  runApp(
    SolarDiagApp(
      database: database,
      auditSecretStore: auditSecretStore,
      showOnboarding: !database.getBool('onboarding_complete'),
    ),
  );
}
