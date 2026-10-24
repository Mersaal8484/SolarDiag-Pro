import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:solardiag_pro/app/solardiag_app.dart';
import 'package:solardiag_pro/config/feature_flags.dart';
import 'package:solardiag_pro/contribution/consent.dart';
import 'package:solardiag_pro/contribution/lifecycle.dart';
import 'package:solardiag_pro/contribution/mock_portal.dart';
import 'package:solardiag_pro/contribution/offline_queue.dart';
import 'package:solardiag_pro/contribution/package.dart';
import 'package:solardiag_pro/contribution/redaction.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/trust/signed_tokens.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';
import 'support/test_secret_store.dart';
import 'support/test_signer.dart';

class _MemoryPackStore implements LibraryPackStore {
  LibraryPack? value;
  RevocationList? revocations;
  int highestSequence = 0;
  @override
  Future<LibraryPack?> load() async => value;
  @override
  Future<void> save(LibraryPack pack) async => value = pack;
  @override
  Future<RevocationList?> loadRevocations() async => revocations;
  @override
  Future<void> saveRevocations(RevocationList revocations) async {
    this.revocations = revocations;
  }
  @override
  Future<int> loadHighestRevocationSequence() async => highestSequence;
  @override
  Future<void> saveHighestRevocationSequence(int sequence) async {
    highestSequence = sequence;
  }
}

void main() {
  const key = [1, 3, 3, 7, 9];
  final lifecycleProfile = DeviceProfile.fromJson(
    jsonDecode(
          File(
            'device_profiles/batteries/_simulated/solardiag_sim.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>,
  );
  final consent = ContributionConsent(
    logs: true,
    samples: false,
    notes: true,
    deviceIdentity: true,
    grantedAt: DateTime.utc(2026),
    consentVersion: '1',
  );

  test(
    'redaction removes seeded sensitive values including hex embedded credentials',
    () {
      const sensitive =
          'serial=SN123456 MAC aa:bb:cc:dd:ee:ff IP 192.168.1.10 SSID=CustomerWifi password=hunter2 GPS 24.7136,46.6753 hostname=site-alpha';
      final hex = utf8
          .encode('password=hidden')
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      final result = const ContributionRedactor().redact(
        '$sensitive $hex',
        sessionSalt: 'session',
      );
      for (final secret in [
        'SN123456',
        'aa:bb:cc:dd:ee:ff',
        '192.168.1.10',
        'CustomerWifi',
        'hunter2',
        '24.7136,46.6753',
        'site-alpha',
        hex,
      ]) {
        expect(result.redacted, isNot(contains(secret)));
      }
      expect(result.changes, isNotEmpty);
    },
  );
  test(
    'redaction covers encoded, IPv6, bare IDs, Arabic digits and deny-list',
    () {
      final base64Secret = base64Encode(utf8.encode('password=hidden'));
      final urlSecret = utf8
          .encode('token=private')
          .map((byte) => '%${byte.toRadixString(16).padLeft(2, '0')}')
          .join();
      final result = const ContributionRedactor().redact(
        '2001:db8::1 aabbccddeeff ABCD1234567890 serial=١٢٣٤٥٦٧٨٩٠ '
        '$base64Secret $urlSecret موقع العميل ألف',
        sessionSalt: 'session-specific-salt',
        denyList: const ['موقع العميل ألف'],
      );
      for (final secret in [
        '2001:db8::1',
        'aabbccddeeff',
        'ABCD1234567890',
        '١٢٣٤٥٦٧٨٩٠',
        base64Secret,
        urlSecret,
        'موقع العميل ألف',
      ]) {
        expect(result.redacted, isNot(contains(secret)));
      }
      expect(result.manualReviewRequired, isFalse);
      expect(result.redacted, contains(RegExp(r'[a-f0-9]{32}>')));
    },
  );

  test('unconsented categories never enter package or sharing manifest', () {
    final package = const ContributionPackager().create(
      data: const ContributionData(
        logs: 'allowed-log',
        samples: 'FORBIDDEN-SAMPLE',
        notes: 'allowed-note',
        deviceIdentity: {'serial': 'FORBIDDEN-DEVICE'},
      ),
      pseudonymousContributorId: 'anonymous',
      consent: ContributionConsent(
        logs: true,
        samples: false,
        notes: true,
        deviceIdentity: false,
        grantedAt: DateTime.utc(2026),
        consentVersion: '2',
      ),
      synthetic: false,
      sessionSalt: 'salt',
      installationKey: key,
    );
    expect(package.payload, isNot(contains('FORBIDDEN-SAMPLE')));
    expect(package.payload, isNot(contains('FORBIDDEN-DEVICE')));
    expect(package.manifest['what_will_be_shared'], ['logs', 'notes']);
  });

  test('package creation fails closed when manual review is required', () {
    expect(
      () => const ContributionPackager().create(
        data: const ContributionData(
          logs: '-----BEGIN PRIVATE KEY----- unsafe material',
        ),
        pseudonymousContributorId: 'anonymous',
        consent: ContributionConsent(
          logs: true,
          samples: false,
          notes: false,
          deviceIdentity: false,
          grantedAt: DateTime.utc(2026),
          consentVersion: '2',
        ),
        synthetic: false,
        sessionSalt: 'salt',
        installationKey: key,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Manual review required'),
        ),
      ),
    );
  });
  test(
    'package is redacted, integrity checked, and rejects synthetic data',
    () {
      const packager = ContributionPackager();
      final package = packager.create(
        data: const ContributionData(
          logs: 'serial=SN123456 voltage=51.2',
          deviceIdentity: {
            'manufacturer': 'Example',
            'model': 'OwnedDevice',
            'firmware': '1.0',
          },
        ),
        pseudonymousContributorId: 'anon-1',
        consent: consent,
        synthetic: false,
        sessionSalt: 's',
        installationKey: key,
      );
      expect(package.payload, isNot(contains('SN123456')));
      expect(packager.verify(package, key), isTrue);
      final tampered = ContributionPackage(
        manifest: package.manifest,
        payload: '${package.payload} altered',
        hash: package.hash,
        signature: package.signature,
      );
      expect(packager.verify(tampered, key), isFalse);
      expect(
        () => packager.create(
          data: const ContributionData(logs: 'x'),
          pseudonymousContributorId: 'a',
          consent: consent,
          synthetic: true,
          sessionSalt: 's',
          installationKey: key,
        ),
        throwsStateError,
      );
    },
  );
  test('revoked consent cannot package data', () {
    final revoked = consent.revoke(DateTime.utc(2026, 2));
    expect(
      () => const ContributionPackager().create(
        data: const ContributionData(logs: 'x'),
        pseudonymousContributorId: 'a',
        consent: revoked,
        synthetic: false,
        sessionSalt: 's',
        installationKey: key,
      ),
      throwsStateError,
    );
  });
  test('offline queue retries then withdraws from mock portal', () async {
    final package = const ContributionPackager().create(
      data: const ContributionData(logs: 'voltage=51.2'),
      pseudonymousContributorId: 'anon',
      consent: consent,
      synthetic: false,
      sessionSalt: 's',
      installationKey: key,
    );
    final queue = OfflineContributionQueue()..enqueue('c1', package);
    final portal = MockContributionPortal()..failNextSubmission = true;
    await queue.flush(portal);
    expect(queue.items.single.state, QueueState.failed);
    await queue.flush(portal);
    expect(queue.items.single.state, QueueState.submitted);
    await queue.withdraw('c1', portal);
    expect(queue.items.single.state, QueueState.withdrawn);
    expect(portal.withdrawn, contains('c1'));
  });
  test('write lifecycle enforces safety review and separation of duties', () {
    final lifecycle = ContributionLifecycle(
      contributionId: 'write-profile',
      profile: lifecycleProfile,
      contributor: AuthenticatedActor.mock(
        'contributor',
        ReviewRole.contributor,
      ),
      createdAt: DateTime.utc(2026),
    );
    var day = 1;
    void advance(ContributionStage stage, String actor, ReviewRole role) =>
        lifecycle.advance(
          to: stage,
          actor: AuthenticatedActor.mock(actor, role),
          at: DateTime.utc(2026, 1, day++),
        );
    advance(ContributionStage.submitted, 'contributor', ReviewRole.contributor);
    advance(ContributionStage.sanitized, 'system', ReviewRole.system);
    advance(ContributionStage.triage, 'system', ReviewRole.system);
    advance(ContributionStage.analysis, 'analyst-a', ReviewRole.analyst);
    advance(ContributionStage.candidate, 'analyst-a', ReviewRole.analyst);
    advance(
      ContributionStage.validation,
      'engineer-b',
      ReviewRole.approvalEngineer,
    );
    expect(
      () => advance(
        ContributionStage.safetyReview,
        'analyst-a',
        ReviewRole.approvalEngineer,
      ),
      throwsStateError,
    );
    advance(
      ContributionStage.safetyReview,
      'engineer-b',
      ReviewRole.approvalEngineer,
    );
    advance(
      ContributionStage.approved,
      'engineer-b',
      ReviewRole.approvalEngineer,
    );
    advance(ContributionStage.signed, 'admin', ReviewRole.administrator);
    advance(ContributionStage.published, 'admin', ReviewRole.administrator);
    expect(lifecycle.stage, ContributionStage.published);
    lifecycle.advance(
      to: ContributionStage.revoked,
      actor: AuthenticatedActor.mock('admin', ReviewRole.administrator),
      at: DateTime.utc(2026, 2),
      reason: 'Unsafe field behavior confirmed',
    );
    expect(lifecycle.stage, ContributionStage.revoked);
  });
  test('write lifecycle cannot skip safety review', () {
    final lifecycle = ContributionLifecycle(
      contributionId: 'cannot-skip',
      profile: lifecycleProfile,
      contributor: AuthenticatedActor.mock(
        'contributor',
        ReviewRole.contributor,
      ),
      createdAt: DateTime.utc(2026),
    );
    expect(
      () => lifecycle.advance(
        to: ContributionStage.approved,
        actor: AuthenticatedActor.mock('admin', ReviewRole.administrator),
        at: DateTime.utc(2026),
      ),
      throwsStateError,
    );
  });

  test('system-only stages and authenticated distinct actors are enforced', () {
    final lifecycle = ContributionLifecycle(
      contributionId: 'identity-rules',
      profile: lifecycleProfile,
      contributor: AuthenticatedActor.mock('person-a', ReviewRole.contributor),
      createdAt: DateTime.utc(2026),
    );
    lifecycle.advance(
      to: ContributionStage.submitted,
      actor: AuthenticatedActor.mock('person-a', ReviewRole.contributor),
      at: DateTime.utc(2026, 1, 2),
    );
    expect(
      () => lifecycle.advance(
        to: ContributionStage.sanitized,
        actor: AuthenticatedActor.mock('person-b', ReviewRole.analyst),
        at: DateTime.utc(2026, 1, 3),
      ),
      throwsStateError,
    );
    lifecycle.advance(
      to: ContributionStage.sanitized,
      actor: AuthenticatedActor.mock('system', ReviewRole.system),
      at: DateTime.utc(2026, 1, 3),
    );
    lifecycle.advance(
      to: ContributionStage.triage,
      actor: AuthenticatedActor.mock('system', ReviewRole.system),
      at: DateTime.utc(2026, 1, 4),
    );
    expect(
      () => lifecycle.advance(
        to: ContributionStage.analysis,
        actor: AuthenticatedActor.mock('person-a', ReviewRole.analyst),
        at: DateTime.utc(2026, 1, 5),
      ),
      throwsStateError,
    );
  });

  test('decline requires a reason', () {
    final declined = ContributionLifecycle(
      contributionId: 'declined',
      profile: lifecycleProfile,
      contributor: AuthenticatedActor.mock('author', ReviewRole.contributor),
      createdAt: DateTime.utc(2026),
    );
    expect(
      () => declined.advance(
        to: ContributionStage.declined,
        actor: AuthenticatedActor.mock('analyst', ReviewRole.analyst),
        at: DateTime.utc(2026, 1, 2),
      ),
      throwsStateError,
    );
    declined.advance(
      to: ContributionStage.declined,
      actor: AuthenticatedActor.mock('analyst', ReviewRole.analyst),
      at: DateTime.utc(2026, 1, 2),
      reason: 'Insufficient provenance',
    );
    expect(declined.stage, ContributionStage.declined);
  });

  test('unauthenticated contributor identity is rejected', () {
    expect(
      () => ContributionLifecycle(
        contributionId: 'anonymous',
        profile: lifecycleProfile,
        contributor: const AuthenticatedActor(
          id: 'anonymous',
          role: ReviewRole.contributor,
          authenticated: false,
        ),
        createdAt: DateTime.utc(2026),
      ),
      throwsStateError,
    );
  });

  group('signed trust contracts', () {
    late TestSigner signer;
    late TestSigner wrongSigner;
    late String simulatorProfile;
    setUp(() async {
      signer = await TestSigner.create(7);
      wrongSigner = await TestSigner.create(99);
      simulatorProfile = await File(
        'device_profiles/batteries/_simulated/solardiag_sim.json',
      ).readAsString();
    });

    Future<LibraryPack> pack(
      int version, {
      String id = 'stable',
      DateTime? expiry,
      int minApp = 1,
      TestSigner? signingSigner,
    }) async {
      final profile = await signer.signProfile(simulatorProfile);
      final payload = {
        'id': id,
        'version': version,
        'min_app_version': minApp,
        'expires_at': (expiry ?? DateTime.utc(2027)).toIso8601String(),
        'profile_hashes': {'sim': profile.contentHash},
      };
      return LibraryPack(
        id: id,
        version: version,
        minAppVersion: minApp,
        expiresAt: expiry ?? DateTime.utc(2027),
        profileHashes: {'sim': profile.contentHash},
        profiles: {'sim': profile},
        signature: await (signingSigner ?? signer).signPayload(payload),
      );
    }

    Future<RevocationList> revocations(
      Set<String> ids, {
      Set<String> profiles = const {},
      int sequence = 1,
    }) async {
      final issuedAt = DateTime.utc(2026, 1, 1);
      final validUntil = DateTime.utc(2026, 12, 31);
      final payload = {
        'sequence': sequence,
        'issued_at': issuedAt.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
        'revoked_packs': ids.toList()..sort(),
        'revoked_profiles': profiles.toList()..sort(),
      };
      return RevocationList(
        sequence: sequence,
        issuedAt: issuedAt,
        validUntil: validUntil,
        revokedPackIds: ids,
        revokedProfileIds: profiles,
        signature: await signer.signPayload(payload),
      );
    }

    test('accepts valid pack and retains last known good', () async {
      final sync = LibrarySync(
        verifier: Ed25519TrustVerifier(signer.publicKeyBytes),
        appVersion: 2,
        store: _MemoryPackStore(),
      );
      expect(
        await sync.apply(
          await pack(1),
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isTrue,
      );
      expect(sync.lastKnownGood!.version, 1);
    });
    test('tampered profile bytes are rejected', () async {
      final valid = await pack(1);
      final signed = valid.profiles['sim']!;
      final tampered = LibraryPack(
        id: valid.id,
        version: valid.version,
        minAppVersion: valid.minAppVersion,
        expiresAt: valid.expiresAt,
        profileHashes: valid.profileHashes,
        profiles: {
          'sim': SignedProfileDocument(
            document: '${signed.document} ',
            contentHash: signed.contentHash,
            signature: signed.signature,
          ),
        },
        signature: valid.signature,
      );
      final sync = LibrarySync(
        verifier: Ed25519TrustVerifier(signer.publicKeyBytes),
        appVersion: 2,
        store: _MemoryPackStore(),
      );
      expect(
        await sync.apply(
          tampered,
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isFalse,
      );
    });
    test('offline restore works and runtime revocation shows banner', () async {
      final store = _MemoryPackStore();
      final verifier = Ed25519TrustVerifier(signer.publicKeyBytes);
      final first = LibrarySync(
        verifier: verifier,
        appVersion: 2,
        store: store,
      );
      expect(
        await first.apply(
          await pack(1),
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isTrue,
      );
      final restarted = LibrarySync(
        verifier: verifier,
        appVersion: 2,
        store: store,
      );
      expect(
        await restarted.restoreOffline(
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isTrue,
      );
      expect(
        await restarted.refreshRevocations(
          await revocations({'stable'}, sequence: 2),
        ),
        isTrue,
      );
      expect(restarted.installed!.showRevokedBanner, isTrue);
      expect(
        restarted.installed!.profileCanWrite('solardiag.simulated.lfp16.v2'),
        isFalse,
      );
    });
    test(
      'revoked physical profile loses write capability immediately',
      () async {
        final json = jsonDecode(simulatorProfile) as Map<String, Object?>
          ..['id'] = 'physical.profile'
          ..['simulated'] = false;
        final capabilities =
            Map<String, Object?>.from(json['capabilities']! as Map)..updateAll(
              (key, _) => key == 'write_parameter'
                  ? 'verifiedHardware'
                  : 'verifiedDocument',
            );
        json['capabilities'] = capabilities;
        json['approval'] = {
          'lifecycle_stage': 'published',
          'approved_by_role': 'approvalEngineer',
          'hardware_validation_record_id': 'hardware-run-physical-profile',
          'verified_capabilities': ['writeParameter'],
        };
        final profile = await signer.signProfile(jsonEncode(json));
        final payload = {
          'id': 'physical-pack',
          'version': 1,
          'min_app_version': 1,
          'expires_at': DateTime.utc(2027).toIso8601String(),
          'profile_hashes': {'physical.profile': profile.contentHash},
        };
        final physicalPack = LibraryPack(
          id: 'physical-pack',
          version: 1,
          minAppVersion: 1,
          expiresAt: DateTime.utc(2027),
          profileHashes: {'physical.profile': profile.contentHash},
          profiles: {'physical.profile': profile},
          signature: await signer.signPayload(payload),
        );
        final sync = LibrarySync(
          verifier: Ed25519TrustVerifier(signer.publicKeyBytes),
          appVersion: 2,
          store: _MemoryPackStore(),
          clock: () => DateTime.utc(2026, 1, 2),
        );
        expect(
          await sync.apply(
            physicalPack,
            now: DateTime.utc(2026),
            revocations: await revocations({}),
          ),
          isTrue,
        );
        expect(sync.installed!.profileCanWrite('physical.profile'), isTrue);
        await sync.refreshRevocations(
          await revocations({}, profiles: {'physical.profile'}, sequence: 2),
        );
        expect(sync.installed!.profileCanWrite('physical.profile'), isFalse);
        expect(sync.installed!.showRevokedBanner, isTrue);
      },
    );
    test('rejects downgrade, expiry, revocation and wrong key', () async {
      LibrarySync newSync() => LibrarySync(
        verifier: Ed25519TrustVerifier(signer.publicKeyBytes),
        appVersion: 2,
        store: _MemoryPackStore(),
      );
      final sync = newSync();
      expect(
        await sync.apply(
          await pack(2),
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isTrue,
      );
      expect(
        await sync.apply(
          await pack(1),
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isFalse,
      );
      expect(
        await newSync().apply(
          await pack(1, expiry: DateTime.utc(2025)),
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isFalse,
      );
      expect(
        await newSync().apply(
          await pack(1, id: 'revoked'),
          now: DateTime.utc(2026),
          revocations: await revocations({'revoked'}),
        ),
        isFalse,
      );
      expect(
        await newSync().apply(
          await pack(1, signingSigner: wrongSigner),
          now: DateTime.utc(2026),
          revocations: await revocations({}),
        ),
        isFalse,
      );
    });
    test(
      'offline entitlement verifies expiry and never hides safety data',
      () async {
        final payload = {
          'subject': 'tech-1',
          'features': ['advanced_diagnostics'],
          'expires_at': DateTime.utc(2027).toIso8601String(),
        };
        final token = EntitlementToken(
          subject: 'tech-1',
          features: const {'advanced_diagnostics'},
          expiresAt: DateTime.utc(2027),
          signature: await signer.signPayload(payload),
        );
        final validator = EntitlementValidator(
          Ed25519TrustVerifier(signer.publicKeyBytes),
        );
        expect(
          await validator.permits(
            token,
            'advanced_diagnostics',
            DateTime.utc(2026),
          ),
          isTrue,
        );
        expect(
          await validator.permits(
            token,
            'advanced_diagnostics',
            DateTime.utc(2028),
          ),
          isFalse,
        );
        expect(validator.safetyInformationVisible('active_alarms'), isTrue);
      },
    );
  });

  testWidgets('contribution flow is hidden by default and available by flag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    expect(find.byTooltip('Contribute'), findsNothing);
    await tester.pumpWidget(
      SolarDiagApp(
        flags: const FeatureFlags(contributionsEnabled: true),
        auditSecretStore: TestSecretStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Contribute'));
    await tester.pumpAndSettle();
    expect(find.text('Contribute safely'), findsOneWidget);
    expect(find.text('Redaction preview'), findsOneWidget);
    expect(find.text('Mock portal only'), findsOneWidget);
  });
}
