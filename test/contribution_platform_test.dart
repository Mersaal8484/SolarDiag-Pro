import 'dart:convert';
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
import 'package:solardiag_pro/trust/signed_tokens.dart';

void main() {
  const key = [1, 3, 3, 7, 9];
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
    'package is redacted, integrity checked, and rejects synthetic data',
    () {
      const packager = ContributionPackager();
      final package = packager.create(
        rawPayload: 'serial=SN123456 voltage=51.2',
        manufacturer: 'Example',
        model: 'OwnedDevice',
        firmware: '1.0',
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
          rawPayload: 'x',
          manufacturer: 'X',
          model: 'Y',
          firmware: '1',
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
        rawPayload: 'x',
        manufacturer: 'X',
        model: 'Y',
        firmware: '1',
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
      rawPayload: 'voltage=51.2',
      manufacturer: 'Example',
      model: 'Owned',
      firmware: '1',
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
    final lifecycle = ContributionLifecycle(hasWriteCapability: true);
    var day = 1;
    void advance(ContributionStage stage, String actor, ReviewRole role) =>
        lifecycle.advance(
          to: stage,
          actorId: actor,
          role: role,
          at: DateTime.utc(2026, 1, day++),
        );
    advance(ContributionStage.submitted, 'contributor', ReviewRole.contributor);
    advance(ContributionStage.sanitized, 'system', ReviewRole.administrator);
    advance(ContributionStage.triage, 'analyst-a', ReviewRole.analyst);
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
  });
  test('write lifecycle cannot skip safety review', () {
    final lifecycle = ContributionLifecycle(hasWriteCapability: true);
    expect(
      () => lifecycle.advance(
        to: ContributionStage.approved,
        actorId: 'admin',
        role: ReviewRole.administrator,
        at: DateTime.utc(2026),
      ),
      throwsStateError,
    );
  });

  group('signed trust contracts', () {
    const signer = MockSigner(key);
    LibraryPack pack(
      int version, {
      String id = 'stable',
      DateTime? expiry,
      int minApp = 1,
      MockSigner signingSigner = signer,
    }) {
      final payload = {
        'id': id,
        'version': version,
        'min_app_version': minApp,
        'expires_at': (expiry ?? DateTime.utc(2027)).toIso8601String(),
        'profile_hashes': const {'sim': 'abc'},
      };
      return LibraryPack(
        id: id,
        version: version,
        minAppVersion: minApp,
        expiresAt: expiry ?? DateTime.utc(2027),
        profileHashes: const {'sim': 'abc'},
        signature: signingSigner.sign(payload),
      );
    }

    RevocationList revocations(Set<String> ids) {
      final payload = {'revoked': ids.toList()..sort()};
      return RevocationList(
        revokedPackIds: ids,
        signature: signer.sign(payload),
      );
    }

    test('accepts valid pack and retains last known good', () {
      final sync = LibrarySync(signer: signer, appVersion: 2);
      expect(
        sync.apply(
          pack(1),
          now: DateTime.utc(2026),
          revocations: revocations({}),
        ),
        isTrue,
      );
      expect(sync.lastKnownGood!.version, 1);
    });
    test('rejects downgrade, expiry, revocation and wrong key', () {
      final sync = LibrarySync(signer: signer, appVersion: 2);
      expect(
        sync.apply(
          pack(2),
          now: DateTime.utc(2026),
          revocations: revocations({}),
        ),
        isTrue,
      );
      expect(
        sync.apply(
          pack(1),
          now: DateTime.utc(2026),
          revocations: revocations({}),
        ),
        isFalse,
      );
      expect(
        LibrarySync(signer: signer, appVersion: 2).apply(
          pack(1, expiry: DateTime.utc(2025)),
          now: DateTime.utc(2026),
          revocations: revocations({}),
        ),
        isFalse,
      );
      expect(
        LibrarySync(signer: signer, appVersion: 2).apply(
          pack(1, id: 'revoked'),
          now: DateTime.utc(2026),
          revocations: revocations({'revoked'}),
        ),
        isFalse,
      );
      expect(
        LibrarySync(signer: signer, appVersion: 2).apply(
          pack(1, signingSigner: const MockSigner([9, 9])),
          now: DateTime.utc(2026),
          revocations: revocations({}),
        ),
        isFalse,
      );
    });
    test('offline entitlement verifies expiry and never hides safety data', () {
      final payload = {
        'subject': 'tech-1',
        'features': ['advanced_diagnostics'],
        'expires_at': DateTime.utc(2027).toIso8601String(),
      };
      final token = EntitlementToken(
        subject: 'tech-1',
        features: const {'advanced_diagnostics'},
        expiresAt: DateTime.utc(2027),
        signature: signer.sign(payload),
      );
      const validator = EntitlementValidator(signer);
      expect(
        validator.permits(token, 'advanced_diagnostics', DateTime.utc(2026)),
        isTrue,
      );
      expect(
        validator.permits(token, 'advanced_diagnostics', DateTime.utc(2028)),
        isFalse,
      );
      expect(validator.safetyInformationVisible('active_alarms'), isTrue);
    });
  });

  testWidgets('contribution flow is hidden by default and available by flag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SolarDiagApp());
    expect(find.byTooltip('Contribute'), findsNothing);
    await tester.pumpWidget(
      const SolarDiagApp(flags: FeatureFlags(contributionsEnabled: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Contribute'));
    await tester.pumpAndSettle();
    expect(find.text('Contribute safely'), findsOneWidget);
    expect(find.text('Redaction preview'), findsOneWidget);
    expect(find.text('Mock portal only'), findsOneWidget);
  });
}
