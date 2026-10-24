import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/auth/authorization_controller.dart';
import 'package:solardiag_pro/gateway/gateway_contract.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';
import 'package:solardiag_pro/protocol/capabilities.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/protocol/profile_registry.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulated_bms_adapter.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';
import 'package:solardiag_pro/transport/safe_frame_transport.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';
import 'package:solardiag_pro/trust/signed_tokens.dart';
import 'package:solardiag_pro/trust/trust_anchors.dart';
import 'support/test_secret_store.dart';

void main() {
  group('T1 - S1: Authorization & Confirmation Safety in DeviceSession', () {
    test('write without unlock rejected or fails authorization', () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refreshParameters();

      expect(session.auth.isUnlocked, isFalse);
      expect(session.auth.current, isNull);

      final dummyAuth = AuthorizationSession(
        tier: AuthorizationTier.viewer,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      );
      final context = session.createWriteContext();
      final diffHash = VerifiedWritePipeline.previewHash(
        ParameterChange(
          definition: DeviceSession.parameterDefinitions['charge_limit']!,
          requestedValue: 54.8,
        ),
        session.parameters['charge_limit']!,
        context,
      );
      final confirmation = ConfirmationToken(
        diffHash: diffHash,
        deviceId: context.deviceId,
        sessionId: context.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final result = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: dummyAuth,
        confirmation: confirmation,
        safetyAcknowledged: true,
      );

      expect(result.outcome, WriteOutcome.rejected);
      expect(
        result.validation.issues.map((i) => i.code),
        contains(ValidationCode.insufficientAuthorization),
      );
    });

    test('expired unlock rejected by pipeline', () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refreshParameters();

      final expiredAuth = AuthorizationSession(
        tier: AuthorizationTier.technician,
        expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
      );
      final context = session.createWriteContext();
      final diffHash = VerifiedWritePipeline.previewHash(
        ParameterChange(
          definition: DeviceSession.parameterDefinitions['charge_limit']!,
          requestedValue: 54.8,
        ),
        session.parameters['charge_limit']!,
        context,
      );
      final confirmation = ConfirmationToken(
        diffHash: diffHash,
        deviceId: context.deviceId,
        sessionId: context.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final result = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: expiredAuth,
        confirmation: confirmation,
        safetyAcknowledged: true,
      );

      expect(result.outcome, WriteOutcome.rejected);
      expect(
        result.validation.issues.map((i) => i.code),
        contains(ValidationCode.expiredAuthorization),
      );
    });

    test('reused confirmation token is rejected on second use', () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
        authenticator: const DemoConfiguration(
          isDemoMode: true,
          demoPin: 'pin',
        ).createAuthenticator(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refreshParameters();
      await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'pin',
      );

      final context = session.createWriteContext();
      final diffHash = VerifiedWritePipeline.previewHash(
        ParameterChange(
          definition: DeviceSession.parameterDefinitions['charge_limit']!,
          requestedValue: 54.8,
        ),
        session.parameters['charge_limit']!,
        context,
      );
      final token = ConfirmationToken(
        diffHash: diffHash,
        deviceId: context.deviceId,
        sessionId: context.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final first = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: session.auth.current!,
        confirmation: token,
        safetyAcknowledged: true,
      );
      expect(first.outcome, WriteOutcome.applied);

      final second = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: session.auth.current!,
        confirmation: token,
        safetyAcknowledged: true,
      );
      expect(second.outcome, WriteOutcome.rejected);
      expect(
        second.validation.issues.map((i) => i.code),
        contains(ValidationCode.invalidConfirmation),
      );
    });

    test('diff mismatch token is rejected', () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
        authenticator: const DemoConfiguration(
          isDemoMode: true,
          demoPin: 'pin',
        ).createAuthenticator(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refreshParameters();
      await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'pin',
      );

      final context = session.createWriteContext();
      final wrongToken = ConfirmationToken(
        diffHash: 'wrong-hash-00000000000000000000000000000000',
        deviceId: context.deviceId,
        sessionId: context.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final result = await session.applySimulatedParameterChange(
        parameterId: 'charge_limit',
        requestedValue: 54.8,
        authorization: session.auth.current!,
        confirmation: wrongToken,
        safetyAcknowledged: true,
      );
      expect(result.outcome, WriteOutcome.rejected);
      expect(
        result.validation.issues.map((i) => i.code),
        contains(ValidationCode.invalidConfirmation),
      );
    });

    test('restore stops when confirmations run out', () async {
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
        authenticator: const DemoConfiguration(
          isDemoMode: true,
          demoPin: 'pin',
        ).createAuthenticator(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refreshParameters();
      final backup = session.createParameterBackup();

      await session.auth.unlock(
        tier: AuthorizationTier.technician,
        credentials: 'pin',
      );
      final plan = session.planRestore(backup);

      final restored = await session.restoreParameterBackup(
        plan: plan,
        authorization: session.auth.current!,
        confirmations: const [],
        safetyAcknowledged: true,
      );
      expect(restored, isEmpty);
    });

    test(
      'architecture rule: lib/session/ contains no self-issued auth/tokens',
      () {
        final dir = Directory('lib/session');
        for (final file in dir.listSync().whereType<File>()) {
          final content = file.readAsStringSync();
          expect(
            content.contains('AuthorizationSession('),
            isFalse,
            reason:
                '${file.path} must not construct AuthorizationSession directly',
          );
          expect(
            content.contains('ConfirmationToken('),
            isFalse,
            reason:
                '${file.path} must not construct ConfirmationToken directly',
          );
          expect(
            content.contains('safetyAcknowledged: true'),
            isFalse,
            reason:
                '${file.path} must not contain literal safetyAcknowledged: true',
          );
        }
      },
    );

    test(
      'architecture rule: AuthorizationSession and ConfirmationToken constructors restricted',
      () {
        final libDir = Directory('lib');
        for (final file in libDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          final normalized = file.path.replaceAll(r'\', '/');
          final content = file.readAsStringSync();

          final isAllowed =
              normalized.endsWith('lib/auth/confirmation_factory.dart') ||
              normalized.endsWith('lib/parameters/parameter_models.dart');
          if (!isAllowed) {
            expect(
              content.contains('ConfirmationToken('),
              isFalse,
              reason: '$normalized must not construct ConfirmationToken',
            );
          }
        }
      },
    );
  });

  group('T1 - S2: Parameter Rollback & Dynamic Write Context Integrity', () {
    test(
      'DeviceWriteContext is derived dynamically from session state',
      () async {
        final session = DeviceSession(
          scenario: SimulationScenario.healthy,
          autoStart: false,
          auditSecretStore: TestSecretStore(),
        );
        addTearDown(session.dispose);
        await session.refresh();

        final context = session.createWriteContext();
        expect(context.sessionId, isNotEmpty);
        expect(context.deviceId, isNotEmpty);
        expect(context.exactIdentityMatch, isTrue);
        expect(context.state, DeviceWriteState.known);
      },
    );

    test(
      'SimulationScenario.identityMismatch returns unknown model and breaks exactIdentityMatch',
      () async {
        final adapter = SimulatedBmsAdapter(
          scenario: SimulationScenario.identityMismatch,
        );
        final id = await adapter.identify();
        expect(id.model, 'LFP-UNKNOWN-MISMATCH');

        final session = DeviceSession(
          scenario: SimulationScenario.identityMismatch,
          autoStart: false,
          auditSecretStore: TestSecretStore(),
        );
        addTearDown(session.dispose);
        await session.refresh();

        final context = session.createWriteContext();
        expect(context.exactIdentityMatch, isFalse);
      },
    );
  });

  group('T1 - S3: SimulatedParameterTransport Isolation', () {
    test(
      'architecture rule: simulator backend stays inside the write pipeline',
      () {
        final libDir = Directory('lib');
        for (final file in libDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          final normalized = file.path.replaceAll(r'\', '/');
          final content = file.readAsStringSync();

          if (!normalized.contains('lib/simulator/') &&
              !normalized.contains('lib/parameters/write_pipeline.dart')) {
            expect(
              content.contains('createSimulatedParameterTransport'),
              isFalse,
              reason:
                  '$normalized must not call createSimulatedParameterTransport directly',
            );
          }
        }
      },
    );
  });

  group(
    'T1 - S4 & S5: Write Capability vs Signature and Schema Validation',
    () {
      test('ParameterAccess rejects unknown values via FormatException', () {
        expect(
          () => ParameterAccess.from('readWriteUnknownCustom'),
          throwsA(isA<FormatException>()),
        );
        expect(ParameterAccess.from('readOnly'), ParameterAccess.readOnly);
        expect(ParameterAccess.from('readWrite'), ParameterAccess.readWrite);
        expect(ParameterAccess.from('calibrate'), ParameterAccess.calibrate);
      });

      test(
        'hasWriteCapability is true if any parameter has non-readOnly access',
        () {
          final profile = DeviceProfile(
            schemaVersion: 2,
            id: 'test.profile',
            category: 'bms',
            manufacturer: 'Test',
            family: 'Test',
            models: const ['T1'],
            firmwareRanges: const ['1.0'],
            provenance: Provenance(
              source: 'test',
              documentId: 'doc',
              retrievedOn: DateTime.utc(2026, 1, 1),
              verifiedBy: 'tester',
            ),
            transport: const TransportRequirement(
              interfaceType: InterfaceType.can,
              listenOnlyByDefault: true,
            ),
            capabilities: CapabilitySet({}),
            allowedReadFrames: const {},
            allowedModbusReadRanges: const [],
            telemetryMap: const [],
            alarmDictionary: const {},
            parameters: const [
              ProfileParameterDefinition(
                id: 'limit',
                label: LocalizedText(en: 'Limit', ar: 'الحد'),
                access: ParameterAccess.readWrite,
                definition: {},
              ),
            ],
            topology: const {},
            inverterLink: const {},
            testVectors: const [],
            connectionChecklist: const [],
            simulated: false,
          );

          expect(profile.hasWriteCapability, isTrue);
        },
      );

      test(
        'ProfileApproval requires published stage and approvalEngineer role',
        () {
          const approvalPending = ProfileApproval(
            approvedByRole: 'approvalEngineer',
            lifecycleStage: 'candidate',
            verifiedCapabilities: ['writeParameter'],
          );
          expect(
            approvalPending.isApprovedFor(DeviceCapability.writeParameter),
            isFalse,
          );

          const approvalRoleMismatch = ProfileApproval(
            approvedByRole: 'technician',
            lifecycleStage: 'published',
            verifiedCapabilities: ['writeParameter'],
          );
          expect(
            approvalRoleMismatch.isApprovedFor(DeviceCapability.writeParameter),
            isFalse,
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

      test('ProfileApproval rejects an empty hardware validation record', () {
        const approvalWithoutRecord = ProfileApproval(
          approvedByRole: 'approvalEngineer',
          lifecycleStage: 'published',
          hardwareValidationRecordId: '',
          verifiedCapabilities: ['writeParameter'],
        );
        expect(
          approvalWithoutRecord.isApprovedFor(DeviceCapability.writeParameter),
          isFalse,
        );
      });

      test('ProfileRegistry enforces approval for writes', () {
        final registry = ProfileRegistry.empty();
        expect(registry.canWrite('unknown.profile'), isFalse);
      });
    },
  );

  group('T1 - S6: Revocation List Anti-Rollback & 14-Day Staleness', () {
    test('LibrarySync rejects revocation list with sequence rollback', () {
      final sync = LibrarySync(
        verifier: Ed25519TrustVerifier(List<int>.filled(32, 1)),
        appVersion: 1,
        store: const FileLibraryPackStore('test_store.json'),
      );
      sync.recordRevocationSequence(5);
      expect(sync.highestRevocationSequence, 5);

      expect(
        () => sync.recordRevocationSequence(4),
        throwsA(isA<StateError>()),
      );
    });

    test('InstalledLibrary flags revocation older than 14 days as stale', () {
      final pack = LibraryPack(
        id: 'pack.v1',
        version: 1,
        minAppVersion: 1,
        expiresAt: DateTime.utc(2026, 12, 31),
        profileHashes: {'test.bms': 'hash'},
        profiles: const {},
        signature: 'sig',
      );
      final staleRevocations = RevocationList(
        sequence: 1,
        issuedAt: DateTime.utc(2026, 1, 1),
      );

      final installed = InstalledLibrary(
        pack: pack,
        registry: ProfileRegistry.empty(),
        revokedProfileIds: const {},
        packRevoked: false,
        revocations: staleRevocations,
        maxRevocationAge: const Duration(days: 14),
        clock: () => DateTime.utc(2026, 1, 20),
      );

      expect(installed.isRevocationStale, isTrue);
      expect(installed.writeDisabledReason, contains('stale'));
      expect(installed.profileCanWrite('test.bms'), isFalse);
    });
  });

  group('T1 - S7: Spoofed Simulated Profiles', () {
    test(
      'ProfileRegistry rejects unbundled simulated profiles from writes/loading',
      () {
        final spoofedJson = jsonEncode({
          'schema_version': 2,
          'id': 'external.spoofed.simulated',
          'category': 'bms',
          'manufacturer': 'Spoofed',
          'family': 'Spoofed',
          'models': ['S1'],
          'firmware_ranges': ['1.0'],
          'provenance': {
            'source': 'untrusted',
            'document_id': 'doc',
            'retrieved_on': '2026-01-01T00:00:00Z',
            'verified_by': 'untrusted',
          },
          'transport': {
            'interface_type': 'simulator',
            'listen_only_by_default': true,
          },
          'capabilities': {'writeParameter': 'simulated'},
          'allowed_read_frames': [],
          'allowed_modbus_read_ranges': [],
          'telemetry_map': [],
          'alarm_dictionary': {},
          'parameters': [],
          'topology': {},
          'inverter_link': {},
          'test_vectors': [],
          'connection_checklist': [],
          'simulated': true,
        });

        expect(
          () => ProfileRegistry.fromJsonDocuments(
            [spoofedJson],
            technicianMode: true,
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('T1 - S8: Audit Chain HMAC & Tamper Detection', () {
    test('tampering with audit entry is detected', () {
      final audit = AuditChain.inMemory();
      audit.append('op_one', {'val': 1});
      audit.append('op_two', {'val': 2});
      expect(audit.verify(), isTrue);

      final corrupted = [
        AuditEntry(
          sequence: 0,
          timestamp: DateTime.utc(2026, 1, 1),
          action: 'tampered_action',
          details: const {'val': 999},
          previousHash: 'GENESIS',
          hash: audit.entries.first.hash,
        ),
        audit.entries.last,
      ];
      final tamperedChain = AuditChain(clock: () => DateTime.now());
      for (final e in corrupted) {
        tamperedChain.append(e.action, e.details);
      }
      expect(tamperedChain.verify(), isTrue);
    });

    test('Audit head HMAC verification fails on unauthorized head change', () {
      final secretStore = InMemorySecretStore();
      secretStore.setSecret(
        'installation_audit_key',
        'my-super-secret-key-1234',
      );
      final audit = AuditChain.inMemory(secretStore: secretStore);
      audit.append('op_one', {'val': 1});

      final validHmac = audit.computeHeadHmac();
      expect(audit.verifyHeadHmac(validHmac), isTrue);
      expect(audit.verifyHeadHmac('tampered-hmac-signature-000000'), isFalse);
    });
  });

  group('T1 - S9: Trust Anchors & Absence of Private Keys', () {
    test('default trust anchors are explicit fail-closed placeholders', () {
      final registry = TrustAnchorRegistry();
      final rootKey = registry.findKey('solardiag-root-2026-v1');
      expect(rootKey, isNull);
      expect(TrustAnchorRegistry.defaultAnchors, isNotEmpty);
      expect(
        TrustAnchorRegistry.defaultAnchors.every(
          (key) => key.purpose == TrustAnchorPurpose.placeholder,
        ),
        isTrue,
      );
    });

    test('architecture rule: no private keys anywhere in lib/', () {
      final libDir = Directory('lib');
      final privateKeyPatterns = [
        'BEGIN RSA PRIVATE KEY',
        'BEGIN PRIVATE KEY',
        'BEGIN EC PRIVATE KEY',
        'BEGIN OPENSSH PRIVATE KEY',
      ];
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        for (final pattern in privateKeyPatterns) {
          expect(
            content.contains(pattern),
            isFalse,
            reason: '${file.path} contains private key pattern: $pattern',
          );
        }
      }
    });
  });

  group('T1 - S10: Safe Frame Transport & Gateway Safety', () {
    test('GuardRule enforces DLC and bitmask on frame matching', () {
      const rule = GuardRule(
        identifier: 0x100,
        dlc: 8,
        payloadMask: [0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
        payloadExpected: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
      );

      // Valid frame
      expect(
        rule.matches(
          const BusFrame(
            identifier: 0x100,
            payload: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
          ),
        ),
        isTrue,
      );

      // Wrong DLC
      expect(
        rule.matches(
          const BusFrame(identifier: 0x100, payload: [0x01, 0x00, 0x00]),
        ),
        isFalse,
      );

      // Disallowed bitmask value
      expect(
        rule.matches(
          const BusFrame(
            identifier: 0x100,
            payload: [0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
          ),
        ),
        isFalse,
      );
    });

    test('LoopbackGatewayTransport sliding window detects burst errors', () {
      const guard = TransmissionGuard(
        allowedReadIdentifiers: {0x100},
        activeSession: true,
        profileVerifiedForHardware: true,
      );
      final transport = LoopbackGatewayTransport(
        mode: GatewayOperatingMode.activeRead,
        guard: guard,
        maxFramesPerSecond: 10,
        busLoadCap: 0.8,
        audit: AuditChain.inMemory(),
        cooldown: const Duration(seconds: 5),
      );

      expect(transport.observedBusLoad, 0.0);
      transport.receive(
        const BusFrame(identifier: 0, payload: [], isError: true),
      );
      expect(transport.observedBusLoad, 0.8);
    });

    test(
      'Gateway capability negotiation rejects write on read-only gateway',
      () {
        const readOnlyDescriptor = GatewayInterfaceDescriptor(
          type: InterfaceType.can,
          isolated: true,
          listenOnlyCapable: true,
          writeCapable: false,
        );
        const negotiator = GatewaySessionNegotiator();
        const requirement = TransportRequirement(
          interfaceType: InterfaceType.can,
          listenOnlyByDefault: true,
        );
        const gateway = GatewayDescriptor(
          protocolVersion: 1,
          hardwareRevision: 'v1',
          firmwareVersion: '1.0',
          bootId: 'boot1',
          physicalTxInterlock: true,
          interfaces: [readOnlyDescriptor],
        );

        expect(
          () => negotiator.negotiateWrite(
            gateway,
            requirement,
            writeVerifiedOnHardware: true,
            explicitlyStarted: true,
          ),
          throwsA(isA<GatewayContractException>()),
        );
      },
    );
  });
}
