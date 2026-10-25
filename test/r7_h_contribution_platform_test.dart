import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/contribution/consent.dart';
import 'package:solardiag_pro/contribution/entitlements.dart';
import 'package:solardiag_pro/contribution/mock_portal.dart';
import 'package:solardiag_pro/contribution/package.dart';
import 'package:solardiag_pro/contribution/platform_api.dart';
import 'package:solardiag_pro/contribution/redaction.dart';
import 'package:solardiag_pro/contribution/reward_ledger.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';
import 'package:solardiag_pro/trust/signed_tokens.dart';

import 'support/test_signer.dart';

void main() {
  test('OpenAPI operationIds exactly match the mock portal contract', () {
    final source = File(
      'docs/contribution_platform/openapi.yaml',
    ).readAsStringSync();
    final operationIds = RegExp(
      r'^\s+operationId:\s+([A-Za-z][A-Za-z0-9_]*)\s*$',
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toSet();
    final ContributionPlatformApi portal = MockContributionPortal();
    expect(operationIds, ContributionPlatformOperations.all);
    expect(portal.supportedOperationIds, operationIds);
  });

  test('mock portal exposes every review and distribution operation', () async {
    final portal = MockContributionPortal();
    const package = ContributionPackage(
      manifest: {'synthetic': false},
      payload: '{}',
      hash: 'hash',
      signature: 'signature',
    );
    await portal.submitContribution('c-1', package);
    expect(await portal.getContribution('c-1'), same(package));
    await portal.quarantineContribution('c-1', accepted: true);
    await portal.triageContribution('c-1', 'reviewed');
    await portal.recordAnalystFinding('c-1', 'evidence-linked');
    await portal.approveContribution('c-1');
    await portal.signContribution('c-1');
    await portal.advanceContributionLifecycle('c-1', 'published');
    await portal.getLatestLibraryPack(LibraryChannel.stable);
    await portal.getRevocations();
    await portal.getEntitlement('tech-1');
    await portal.withdrawContribution('c-1');
    expect(
      portal.operationLog.map((entry) => entry.split(':').first).toSet(),
      ContributionPlatformOperations.all,
    );
  });

  test('reward points follow verified value, not submission volume', () {
    final ledger = RewardLedger();
    final first = ledger.append(
      contributionId: 'c-1',
      contributorId: 'author',
      occurredAt: DateTime.utc(2026, 1, 1),
      evidence: const RewardEvidence(
        evidenceQuality: .8,
        newCoverage: true,
        reproducible: true,
      ),
    );
    final duplicate = ledger.append(
      contributionId: 'c-2',
      contributorId: 'author',
      occurredAt: DateTime.utc(2026, 1, 1),
      evidence: const RewardEvidence(
        evidenceQuality: 1,
        newCoverage: true,
        reproducible: true,
        hardwareVerified: true,
        duplicateOf: 'c-1',
      ),
    );
    final falseData = ledger.append(
      contributionId: 'c-3',
      contributorId: 'author',
      occurredAt: DateTime.utc(2026, 1, 1),
      evidence: const RewardEvidence(evidenceQuality: 0, falseData: true),
    );
    expect(first.points, 84);
    expect(duplicate.points, 0);
    expect(falseData.points, -100);
    expect(ledger.entries, hasLength(3));
    expect(ledger.verifyIntegrity(), isTrue);
    expect(
      () => ledger.append(
        contributionId: 'c-1',
        contributorId: 'author',
        occurredAt: DateTime.utc(2026, 1, 2),
        evidence: const RewardEvidence(evidenceQuality: 1),
      ),
      throwsStateError,
    );
  });

  test('reward rate limits do not suppress false-data deductions', () {
    final ledger = RewardLedger(
      policy: const RewardPolicy(maximumPositiveEventsPerDay: 1),
    );
    RewardLedgerEntry append(String id, RewardEvidence evidence) =>
        ledger.append(
          contributionId: id,
          contributorId: 'author',
          occurredAt: DateTime.utc(2026),
          evidence: evidence,
        );
    expect(append('one', const RewardEvidence(evidenceQuality: 1)).points, 30);
    expect(append('two', const RewardEvidence(evidenceQuality: 1)).points, 0);
    expect(
      append(
        'false',
        const RewardEvidence(evidenceQuality: 0, falseData: true),
      ).points,
      -100,
    );
  });

  test(
    'entitlement config never hides safety data for any token state',
    () async {
      final policy = EntitlementPolicy.fromJson(
        jsonDecode(File('config/entitlements.json').readAsStringSync())
            as Map<String, Object?>,
      );
      final signer = await TestSigner.create(71);
      final validator = EntitlementValidator(
        Ed25519TrustVerifier(signer.publicKeyBytes),
      );
      final expiredPayload = {
        'subject': 'tech-1',
        'features': ['advanced_diagnostics'],
        'expires_at': DateTime.utc(2025).toIso8601String(),
      };
      final expired = EntitlementToken(
        subject: 'tech-1',
        features: const {'advanced_diagnostics'},
        expiresAt: DateTime.utc(2025),
        signature: await signer.signPayload(expiredPayload),
      );
      final access = EntitlementAccessController(
        policy: policy,
        validator: validator,
      );
      expect(
        await access.canAccess(
          feature: 'basic_diagnostics',
          now: DateTime.utc(2026),
        ),
        isTrue,
      );
      expect(
        await access.canAccess(
          feature: 'advanced_diagnostics',
          now: DateTime.utc(2026),
        ),
        isFalse,
      );
      for (final feature in policy.safetyCriticalFeatures) {
        expect(
          await access.canAccess(feature: feature, now: DateTime.utc(2026)),
          isTrue,
        );
        expect(
          await access.canAccess(
            feature: feature,
            token: expired,
            now: DateTime.utc(2026),
          ),
          isTrue,
        );
      }
      expect(
        await access.canAccess(
          feature: 'advanced_diagnostics',
          token: expired,
          now: DateTime.utc(2026),
        ),
        isFalse,
      );
      expect(
        () => EntitlementPolicy.fromJson({
          'schema_version': 1,
          'safety_critical_features': <String>[],
          'free_features': <String>[],
          'paid_features': <String>[],
        }),
        throwsFormatException,
      );
    },
  );

  test('no package contains raw, hex, or base64 sensitive corpus', () {
    const seeded = [
      'serial=SN12345678',
      'mac=aa:bb:cc:dd:ee:ff',
      'ip=192.168.20.15',
      'ssid=CustomerNetwork',
      'password=correct-horse',
      '24.713600,46.675300',
      'Customer Name',
    ];
    String hex(String value) => utf8
        .encode(value)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final encoded = [
      for (final value in seeded) hex(value),
      for (final value in seeded) base64Encode(utf8.encode(value)),
    ];
    final corpus = [...seeded, ...encoded].join('\n');
    final result = const ContributionRedactor().redact(
      corpus,
      sessionSalt: 'r7-h-corpus',
      denyList: const ['Customer Name'],
    );
    final package = const ContributionPackager().create(
      data: ContributionData(logs: corpus),
      pseudonymousContributorId: 'corpus-author',
      consent: ContributionConsent(
        logs: true,
        samples: false,
        notes: false,
        deviceIdentity: false,
        grantedAt: DateTime.utc(2026),
        consentVersion: 'r7-h',
      ),
      synthetic: false,
      sessionSalt: 'r7-h-corpus',
      installationKey: const [7, 1, 7],
      denyList: const ['Customer Name'],
    );
    for (final secret in [...seeded, ...encoded]) {
      expect(result.redacted, isNot(contains(secret)));
      expect(package.encode(), isNot(contains(secret)));
    }
    expect(result.manualReviewRequired, isFalse);
  });

  test('reward ledger has no write or safety-gate dependency', () {
    final source = File(
      'lib/contribution/reward_ledger.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('write_pipeline')));
    expect(source, isNot(contains('write_authorization')));
    expect(source, isNot(contains('authorization_controller')));
    expect(source, isNot(contains('transport/')));
  });
}
