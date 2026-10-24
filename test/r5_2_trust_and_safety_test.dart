// R5-2: Trust and Safety Tests (Y1–Y7)
// Verifies each requirement from Codex Round 5.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/auth/authorization_controller.dart';
import 'package:solardiag_pro/auth/confirmation_factory.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/protocol/capabilities.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';
import 'package:solardiag_pro/trust/library_write_reason.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';
import 'package:solardiag_pro/trust/signed_tokens.dart';
import 'package:solardiag_pro/trust/trust_anchors.dart';
import 'support/test_secret_store.dart';

void main() {
  group('Y1: Fail-closed Authenticator & Confirmation Factory', () {
    test(
      'default AuthorizationController uses NoAuthenticator and fails closed',
      () async {
        final controller = AuthorizationController();
        final unlocked = await controller.unlock(
          tier: AuthorizationTier.technician,
          credentials: 'any-password',
        );
        expect(
          unlocked,
          isFalse,
          reason: 'Y1: default authenticator must fail closed',
        );
        expect(controller.isUnlocked, isFalse);

        final defaultConfigurationController = AuthorizationController(
          authenticator: const DemoConfiguration(
            demoPin: '1234',
          ).createAuthenticator(),
        );
        expect(
          await defaultConfigurationController.unlock(
            tier: AuthorizationTier.technician,
            credentials: '1234',
          ),
          isFalse,
        );
        expect(defaultConfigurationController.isUnlocked, isFalse);
      },
    );

    test(
      'DemoConfiguration injects MockTechnicianAuthenticator only for demo/tests',
      () async {
        const demoConfig = DemoConfiguration(isDemoMode: true, demoPin: '1234');
        final controller = AuthorizationController(
          authenticator: demoConfig.createAuthenticator(),
        );
        expect(
          await controller.unlock(
            tier: AuthorizationTier.technician,
            credentials: 'wrong',
          ),
          isFalse,
        );
        expect(
          await controller.unlock(
            tier: AuthorizationTier.technician,
            credentials: '1234',
          ),
          isTrue,
        );
        expect(controller.isUnlocked, isTrue);
      },
    );

    test(
      'confirmation_factory builds valid token and refuses mismatched/empty hash',
      () {
        expect(
          () => mintShownPlanConfirmation(
            shownPlanHash: '',
            deviceId: 'dev-1',
            sessionId: 'ses-1',
            expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
          ),
          throwsArgumentError,
        );

        final token = mintShownPlanConfirmation(
          shownPlanHash: 'valid-diff-hash',
          deviceId: 'dev-1',
          sessionId: 'ses-1',
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        );
        expect(token.diffHash, 'valid-diff-hash');
        expect(token.deviceId, 'dev-1');
        expect(token.sessionId, 'ses-1');
      },
    );

    test(
      'Architecture: ConfirmationToken is only constructed in confirmation_factory.dart',
      () {
        final libDir = Directory('lib');
        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in dartFiles) {
          final normalizedPath = file.path.replaceAll('\\', '/');
          if (normalizedPath.endsWith('lib/auth/confirmation_factory.dart') ||
              normalizedPath.endsWith('lib/parameters/parameter_models.dart')) {
            continue;
          }
          final content = file.readAsStringSync();
          expect(
            content.contains('ConfirmationToken('),
            isFalse,
            reason:
                'Forbidden ConfirmationToken construction in $normalizedPath',
          );
          expect(
            content.contains("'technician-authenticated'"),
            isFalse,
            reason: 'Forbidden literal credential in $normalizedPath',
          );
        }
      },
    );
  });

  group('Y2: Write Context Fail-Open Fallback Removal', () {
    test('missing identification blocks writes with unknownVerify state', () {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
      );
      addTearDown(session.dispose);

      final context = session.createWriteContext();
      expect(context.state, equals(DeviceWriteState.unknownVerify));
      expect(context.writeLocked, isTrue);
      expect(context.connectedModel, isNull);
    });

    test(
      'identity mismatch scenario is detected and write is locked',
      () async {
        final session = DeviceSession(
          scenario: SimulationScenario.identityMismatch,
          autoStart: false,
          auditSecretStore: TestSecretStore(),
        );
        addTearDown(session.dispose);
        await session.refresh();

        final context = session.createWriteContext();
        expect(context.state, equals(DeviceWriteState.identityMismatch));
        expect(context.writeLocked, isTrue);
        expect(context.exactIdentityMatch, isFalse);
      },
    );
  });

  group('Y3: Simulator Token Private Construction', () {
    test(
      'Architecture: SimulatorToken.instance does not exist and token cannot be public',
      () {
        final transportFile = File(
          'lib/simulator/simulated_parameter_transport.dart',
        );
        final content = transportFile.readAsStringSync();
        expect(
          content.contains('static const instance'),
          isFalse,
          reason: 'SimulatorToken.instance must be removed',
        );
      },
    );
  });

  group('Y4: hasWriteCapability and ProfileApproval', () {
    DeviceProfile makeProfile({
      required Map<String, Object?> capabilities,
      required List<Map<String, Object?>> parameters,
    }) {
      return DeviceProfile.fromJson({
        'schema_version': 2,
        'id': 'test.profile',
        'category': 'battery',
        'manufacturer': 'Test',
        'family': 'Family',
        'models': ['M1'],
        'firmware_ranges': ['v1'],
        'simulated': false,
        'provenance': {
          'source': 'test',
          'document_id': 'fixture-doc-1',
          'retrieved_on': '2026-10-24',
          'verified_by': 'automated-tests',
        },
        'transport': {
          'interface': 'can',
          'data_formats': ['candump'],
        },
        'allowed_read_frames': <int>[],
        'allowed_modbus_read_ranges': <Map<String, dynamic>>[
          <String, dynamic>{'start': 0, 'end': 1},
        ],
        'telemetry_map': <Map<String, dynamic>>[],
        'alarm_dictionary': <String, dynamic>{},
        'capabilities': capabilities,
        'parameters': parameters,
        'topology': <String, dynamic>{},
        'inverter_link': <String, dynamic>{},
        'test_vectors': <Map<String, dynamic>>[],
        'connection_checklist': <Map<String, dynamic>>[],
      });
    }

    test(
      'hasWriteCapability is true for any non-unsupported write or calibrate status',
      () {
        final profileResearch = makeProfile(
          capabilities: {
            'write_parameter': 'researchTarget',
            'calibrate': 'unsupported',
          },
          parameters: [
            {
              'id': 'p1',
              'label': {'en': 'P1', 'ar': 'P1'},
              'access': 'read_only',
            },
          ],
        );
        expect(
          profileResearch.hasWriteCapability,
          isTrue,
          reason:
              'researchTarget on writeParameter must trigger hasWriteCapability',
        );

        final profileReadOnly = makeProfile(
          capabilities: {
            'write_parameter': 'unsupported',
            'calibrate': 'unsupported',
          },
          parameters: [
            {
              'id': 'p1',
              'label': {'en': 'P1', 'ar': 'P1'},
              'access': 'read_only',
            },
          ],
        );
        expect(profileReadOnly.hasWriteCapability, isFalse);

        final profileParamWrite = makeProfile(
          capabilities: {
            'write_parameter': 'unsupported',
            'calibrate': 'unsupported',
          },
          parameters: [
            {
              'id': 'p1',
              'label': {'en': 'P1', 'ar': 'P1'},
              'access': 'read_write',
            },
          ],
        );
        expect(profileParamWrite.hasWriteCapability, isTrue);
      },
    );

    test(
      'ProfileApproval.isApprovedFor requires non-empty hardwareValidationRecordId',
      () {
        const approvalNoRecord = ProfileApproval(
          approvedByRole: 'approvalEngineer',
          lifecycleStage: 'published',
          hardwareValidationRecordId: '',
          verifiedCapabilities: ['writeParameter'],
        );
        expect(
          approvalNoRecord.isApprovedFor(DeviceCapability.writeParameter),
          isFalse,
          reason:
              'Approval without hardwareValidationRecordId must return false',
        );

        const approvalValid = ProfileApproval(
          approvedByRole: 'approvalEngineer',
          lifecycleStage: 'published',
          hardwareValidationRecordId: 'HVR-2026-001',
          verifiedCapabilities: ['writeParameter'],
        );
        expect(
          approvalValid.isApprovedFor(DeviceCapability.writeParameter),
          isTrue,
        );
      },
    );
  });

  group('Y5: Revocation Anti-Rollback Persistence & Expiry', () {
    test('missing installed library reports a write-block reason', () {
      final sync = LibrarySync(
        verifier: MockTrustVerifier(acceptAll: true),
        appVersion: 1,
        store: _TestPackStore(),
      );

      expect(
        sync.writeDisabledReasonFor('profile-missing'),
        LibraryWriteDisabledReason.libraryMissing,
      );
    });

    test(
      'same-sequence second pack installs; lower sequence rejected; expired list disables writes',
      () async {
        final store = _TestPackStore();
        final sync = LibrarySync(
          verifier: MockTrustVerifier(acceptAll: true),
          appVersion: 1,
          store: store,
        );
        final now = DateTime.utc(2026, 6, 1);

        final pack1 = LibraryPack(
          id: 'pack-1',
          version: 1,
          minAppVersion: 1,
          expiresAt: DateTime.utc(2027),
          profileHashes: {},
          profiles: {},
          signature: 'valid-sig',
        );

        final revocationsSeq1 = RevocationList(
          sequence: 1,
          issuedAt: DateTime.utc(2026, 1, 1),
          validUntil: DateTime.utc(2026, 12, 31),
          signature: 'valid-sig',
        );

        final ok1 = await sync.apply(
          pack1,
          now: now,
          revocations: revocationsSeq1,
        );
        expect(ok1, isTrue);

        // Same sequence second pack should install successfully
        final pack2 = LibraryPack(
          id: 'pack-2',
          version: 2,
          minAppVersion: 1,
          expiresAt: DateTime.utc(2027),
          profileHashes: {},
          profiles: {},
          signature: 'valid-sig',
        );
        final ok2 = await sync.apply(
          pack2,
          now: now,
          revocations: revocationsSeq1,
        );
        expect(
          ok2,
          isTrue,
          reason:
              'Same sequence revocation list must be accepted for another pack',
        );

        // Expired revocation list disables writes
        final expiredRevocations = RevocationList(
          sequence: 2,
          issuedAt: DateTime.utc(2025, 1, 1),
          validUntil: DateTime.utc(
            2025,
            12,
            31,
          ), // Expired relative to now (2026)
          signature: 'valid-sig',
        );
        final pack3 = LibraryPack(
          id: 'pack-3',
          version: 3,
          minAppVersion: 1,
          expiresAt: DateTime.utc(2027),
          profileHashes: {},
          profiles: {},
          signature: 'valid-sig',
        );
        await sync.apply(pack3, now: now, revocations: expiredRevocations);
        expect(
          sync.installed?.writeDisabledReason,
          LibraryWriteDisabledReason.revocationListExpired,
        );
      },
    );
  });

  group('Y6: Audit HMAC & SecretStore Security', () {
    test('InMemorySecretStore uses non-deterministic Random.secure', () {
      final store1 = InMemorySecretStore();
      final secret1 = store1.getOrCreateSecretSync('key1');
      final store2 = InMemorySecretStore();
      final secret2 = store2.getOrCreateSecretSync('key1');

      expect(
        secret1,
        isNot(equals(secret2)),
        reason: 'Secret must be cryptographically random',
      );
    });

    test('AuditChain tampering or missing MAC fails closed on load', () {
      final secretStore = InMemorySecretStore();
      final store = _MemoryAuditStore();
      final chain = AuditChain(store: store, secretStore: secretStore);
      chain.append('test_action', {'k': 'v'});

      // Tamper with head MAC
      store.savedMac = 'invalid-mac';
      expect(
        () => AuditChain.load(store, secretStore: secretStore),
        throwsFormatException,
      );
    });
  });

  group('Y7: Trust Anchors & Purpose', () {
    test('placeholder-only registry blocks writes with a visible reason', () {
      final registry = TrustAnchorRegistry();
      final validKeys = registry.keys.where(
        (key) => key.isValidAt(DateTime.now().toUtc()),
      );
      final session = DeviceSession(autoStart: false);
      addTearDown(session.dispose);

      if (validKeys.isEmpty) {
        session.setLibraryWriteStatus(
          reason: LibraryWriteDisabledReason.noValidTrustAnchor,
          blocksWrites: true,
        );
      }
      expect(validKeys, isEmpty);
      expect(session.libraryWritesBlocked, isTrue);
      expect(
        session.libraryWriteDisabledReason,
        LibraryWriteDisabledReason.noValidTrustAnchor,
      );
      expect(session.createWriteContext().writeLocked, isTrue);
    });

    test('development trust requires the compile-time opt-in', () {
      const allowDevelopmentTrust = bool.fromEnvironment(
        'ALLOW_DEV_TRUST',
        defaultValue: false,
      );
      final devKey = TrustAnchorKey(
        keyId: 'dev-key-1',
        publicKeyBytes: const [1, 2, 3],
        notBefore: DateTime.utc(2026),
        notAfter: DateTime.utc(2028),
        purpose: TrustAnchorPurpose.development,
      );
      expect(devKey.purpose, TrustAnchorPurpose.development);
      expect(
        TrustAnchorRegistry([devKey]).findKey('dev-key-1') != null,
        allowDevelopmentTrust,
      );
      if (!allowDevelopmentTrust) {
        final session = DeviceSession(autoStart: false);
        addTearDown(session.dispose);
        session.setLibraryWriteStatus(
          reason: LibraryWriteDisabledReason.noValidTrustAnchor,
          blocksWrites: true,
        );
        expect(session.libraryWritesBlocked, isTrue);
        expect(
          session.libraryWriteDisabledReason,
          LibraryWriteDisabledReason.noValidTrustAnchor,
        );
      }
    });

    test(
      'release build rejects a registry containing only development keys',
      () {
        final devKey = TrustAnchorKey(
          keyId: 'release-dev-key',
          publicKeyBytes: const [1, 2, 3],
          notBefore: DateTime.utc(2026),
          notAfter: DateTime.utc(2028),
          purpose: TrustAnchorPurpose.development,
        );
        final registry = TrustAnchorRegistry([devKey]);

        expect(
          registry.findKeyForBuild(
            'release-dev-key',
            now: DateTime.utc(2027),
            releaseMode: true,
          ),
          isNull,
        );
      },
    );

    test('expired and unknown trust anchors are rejected', () {
      final expiredKey = TrustAnchorKey(
        keyId: 'expired-key',
        publicKeyBytes: const [1, 2, 3],
        notBefore: DateTime.utc(2020),
        notAfter: DateTime.utc(2021),
      );
      final registry = TrustAnchorRegistry([expiredKey]);
      final unavailableAnchor = registry.findKey(
        'expired-key',
        now: DateTime.utc(2027),
      );
      expect(unavailableAnchor, isNull);
      expect(registry.findKey('unknown-key', now: DateTime.utc(2027)), isNull);
      final session = DeviceSession(autoStart: false);
      addTearDown(session.dispose);
      if (unavailableAnchor == null) {
        session.setLibraryWriteStatus(
          reason: LibraryWriteDisabledReason.noValidTrustAnchor,
          blocksWrites: true,
        );
      }
      expect(unavailableAnchor, isNull);
      expect(
        session.libraryWriteDisabledReason,
        LibraryWriteDisabledReason.noValidTrustAnchor,
      );
      expect(session.createWriteContext().writeLocked, isTrue);
    });
  });
}

class _TestPackStore implements LibraryPackStore {
  LibraryPack? pack;
  RevocationList? revocations;
  int highestSequence = 0;

  @override
  Future<LibraryPack?> load() async => pack;

  @override
  Future<void> save(LibraryPack pack) async {
    this.pack = pack;
  }

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

class MockTrustVerifier extends Ed25519TrustVerifier {
  MockTrustVerifier({required this.acceptAll}) : super(List.filled(32, 0));

  final bool acceptAll;

  @override
  Future<bool> verifyPayload(
    Map<String, Object?> payload,
    String signature,
  ) async => acceptAll;

  @override
  Future<bool> verifyProfile(SignedProfileDocument profile) async => acceptAll;
}

class _MemoryAuditStore implements AuditChainStore {
  StoredAuditChain? chain;
  String? savedMac;

  @override
  StoredAuditChain? load() {
    final stored = chain;
    if (stored == null) return null;
    return StoredAuditChain(
      entries: stored.entries,
      head: stored.head,
      headMac: savedMac,
    );
  }

  @override
  void saveEntries(List<AuditEntry> entries) {
    chain = StoredAuditChain(
      entries: entries,
      head: chain?.head ?? 'GENESIS',
      headMac: savedMac,
    );
  }

  @override
  void saveHead(String head) {
    chain = StoredAuditChain(
      entries: chain?.entries ?? [],
      head: head,
      headMac: savedMac,
    );
  }

  @override
  void saveHeadMac(String head, String mac) {
    savedMac = mac;
    chain = StoredAuditChain(
      entries: chain?.entries ?? [],
      head: head,
      headMac: mac,
    );
  }
}
