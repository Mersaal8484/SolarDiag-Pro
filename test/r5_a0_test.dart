import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/config/feature_flags.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';
import 'package:solardiag_pro/trust/library_write_reason.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';
import 'package:solardiag_pro/trust/signed_tokens.dart';

void main() {
  test('session derives simulator identity instead of embedding literals', () {
    final source = File('lib/session/device_session.dart').readAsStringSync();
    for (final forbidden in [
      'LFP-16S-SIM',
      'simulator-v2',
      'SOLARDIAG-SIM-BMS',
      'solardiag.simulated.lfp16.v2',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });

  test('an identification mismatch still blocks parameter writes', () async {
    final session = DeviceSession(
      scenario: SimulationScenario.identityMismatch,
      autoStart: false,
    );
    addTearDown(session.dispose);
    await session.refresh();

    final context = session.createWriteContext();
    expect(context.state, DeviceWriteState.identityMismatch);
    expect(context.writeLocked, isTrue);
  });

  test('backend isolation: implementations stay inside simulator library', () {
    final directory = Directory('lib');
    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final normalized = file.path.replaceAll(r'\', '/');
      if (normalized.contains('lib/simulator/')) continue;
      expect(
        file.readAsStringSync().contains(
          'implements SimulatedParameterBackend',
        ),
        isFalse,
        reason: '$normalized must not implement the simulator backend',
      );
    }
  });

  test('library feature flag is off by default', () {
    expect(const FeatureFlags().libraryEnabled, isFalse);
  });

  test('signed revocations persist and are applied after restart', () async {
    final directory = await Directory.systemTemp.createTemp('r5-a0-library-');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileLibraryPackStore(
      '${directory.path}${Platform.pathSeparator}library.pack.json',
    );
    final now = DateTime.utc(2027, 1, 1);
    final firstSession = DeviceSession(autoStart: false);
    addTearDown(firstSession.dispose);
    final pack = LibraryPack(
      id: 'offline-pack',
      version: 1,
      minAppVersion: 1,
      expiresAt: DateTime.utc(2030),
      profileHashes: const {},
      profiles: const {},
      signature: 'accepted-by-test-verifier',
    );
    final initialRevocations = RevocationList(
      sequence: 1,
      issuedAt: DateTime.utc(2027),
      validUntil: DateTime.utc(2030),
      revokedProfileIds: const {},
      signature: 'accepted-by-test-verifier',
    );
    final firstSync = LibrarySync(
      verifier: _AcceptingVerifier(),
      appVersion: 1,
      store: store,
    );
    expect(
      await firstSync.apply(pack, now: now, revocations: initialRevocations),
      isTrue,
    );
    final revocations = RevocationList(
      sequence: 2,
      issuedAt: DateTime.utc(2027),
      validUntil: DateTime.utc(2030),
      revokedPackIds: const {'offline-pack'},
      revokedProfileIds: {firstSession.activeProfileId},
      signature: 'accepted-by-test-verifier',
    );
    expect(await firstSync.refreshRevocations(revocations), isTrue);

    final restartedSync = LibrarySync(
      verifier: _AcceptingVerifier(),
      appVersion: 1,
      store: store,
    );
    expect(await restartedSync.restoreOffline(now: now), isTrue);
    expect(restartedSync.installed!.packRevoked, isTrue);
    expect(restartedSync.installed!.showRevokedBanner, isTrue);
    expect(
      restartedSync.installed!.revokedProfileIds,
      contains(firstSession.activeProfileId),
    );
    final restartedSession = DeviceSession(autoStart: false);
    addTearDown(restartedSession.dispose);
    final writeBlockReason = restartedSync.writeDisabledReasonFor(
      restartedSession.activeProfileId,
    );
    restartedSession.setLibraryWriteStatus(
      reason: writeBlockReason,
      blocksWrites: writeBlockReason != null,
    );
    expect(restartedSession.libraryWritesBlocked, isTrue);
    expect(writeBlockReason, LibraryWriteDisabledReason.revoked);
    expect(
      restartedSync.installed!.profileCanWrite(
        restartedSession.activeProfileId,
      ),
      isFalse,
    );
  });

  test('session records a library revocation write block', () async {
    final session = DeviceSession(autoStart: false);
    addTearDown(session.dispose);
    await session.refresh();

    session.setLibraryWriteStatus(
      reason: LibraryWriteDisabledReason.noValidTrustAnchor,
      blocksWrites: true,
    );
    expect(session.libraryWritesBlocked, isTrue);
    expect(
      session.libraryWriteDisabledReason,
      LibraryWriteDisabledReason.noValidTrustAnchor,
    );
    expect(session.createWriteContext().writeLocked, isTrue);
  });
}

class _AcceptingVerifier extends Ed25519TrustVerifier {
  _AcceptingVerifier() : super(List.filled(32, 0));

  @override
  Future<bool> verifyPayload(
    Map<String, Object?> payload,
    String signature,
  ) async => true;

  @override
  Future<bool> verifyProfile(SignedProfileDocument profile) async => true;
}
