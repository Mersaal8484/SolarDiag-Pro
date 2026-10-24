import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

/// Generates an Ed25519 development trust anchor key pair.
/// The public anchor is written to a committed JSON/Dart structure, while
/// any private material is written strictly to a git-ignored development path.
Future<void> main() async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

  final anchor = {
    'key_id': 'solardiag-dev-root-${DateTime.now().toUtc().year}',
    'purpose': 'development',
    'public_key_bytes': publicKey.bytes,
    'not_before': '2026-01-01T00:00:00.000Z',
    'not_after': '2028-01-01T00:00:00.000Z',
  };

  final outDir = Directory('.dev_keys');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final gitignore = File('.dev_keys/.gitignore');
  if (!gitignore.existsSync()) {
    gitignore.writeAsStringSync('*\n!.gitignore\n');
  }

  final privateFile = File('.dev_keys/dev_private_key.bin');
  privateFile.writeAsBytesSync(privateKeyBytes);

  stdout.writeln('Development Trust Anchor generated successfully:');
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(anchor));
}
