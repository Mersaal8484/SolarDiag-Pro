import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/protocol/capabilities.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/protocol/profile_registry.dart';
import 'package:solardiag_pro/trust/profile_integrity.dart';
import 'package:solardiag_pro/transport/safe_frame_transport.dart';
import 'support/test_signer.dart';

void main() {
  late String simulatorProfile;
  setUpAll(
    () => simulatorProfile = File(
      'device_profiles/batteries/_simulated/solardiag_sim.json',
    ).readAsStringSync(),
  );

  test('simulator profile validates and registers', () {
    final registry = ProfileRegistry.fromJsonDocuments(
      [simulatorProfile],
      technicianMode: true,
      isBundled: true,
    );
    final profile = registry.byId('solardiag.simulated.lfp16.v2');
    expect(profile, isNotNull);
    expect(profile!.simulated, isTrue);
    expect(profile.transport.interfaceType, InterfaceType.simulator);
    expect(
      profile.capabilities.statusOf(DeviceCapability.readLive),
      VerificationStatus.simulated,
    );
  });

  test('invalid profile schema is rejected', () {
    final json = jsonDecode(simulatorProfile) as Map<String, Object?>
      ..['schema_version'] = 999;
    expect(() => DeviceProfile.fromJson(json), throwsFormatException);
  });

  test(
    'duplicate profile identifiers are rejected',
    () => expect(
      () => ProfileRegistry.fromJsonDocuments(
        [simulatorProfile, simulatorProfile],
        technicianMode: true,
        isBundled: true,
      ),
      throwsFormatException,
    ),
  );

  test('technician mode rejects unsigned physical profiles', () {
    final json = jsonDecode(simulatorProfile) as Map<String, Object?>
      ..['simulated'] = false;
    final capabilities = Map<String, Object?>.from(json['capabilities']! as Map)
      ..updateAll((_, _) => 'researchTarget');
    json['capabilities'] = capabilities;
    expect(
      () => ProfileRegistry.fromJsonDocuments([
        jsonEncode(json),
      ], technicianMode: true),
      throwsFormatException,
    );
  });

  test(
    'developer mode admits unsigned physical profile as read-only',
    () async {
      final json = jsonDecode(simulatorProfile) as Map<String, Object?>
        ..['simulated'] = false;
      final capabilities = Map<String, Object?>.from(
        json['capabilities']! as Map,
      )..updateAll((_, _) => 'researchTarget');
      json['capabilities'] = capabilities;
      final document = jsonEncode(json);
      final signer = await TestSigner.create(21);
      final registry = await ProfileRegistry.fromSignedDocuments(
        [
          SignedProfileDocument(
            document: document,
            contentHash: sha256Hex(document),
            signature: base64Encode(List<int>.filled(64, 0)),
          ),
        ],
        verifier: Ed25519TrustVerifier(signer.publicKeyBytes),
        technicianMode: false,
        developerMode: true,
      );
      expect(registry.profiles, hasLength(1));
      expect(registry.profileCanWrite('solardiag.simulated.lfp16.v2'), isFalse);
    },
  );

  group('transmission guard', () {
    const readFrame = BusFrame(identifier: 0x301, payload: [1, 2]);
    test('blocks all frames without an active session', () {
      const guard = TransmissionGuard(
        allowedReadIdentifiers: {0x301},
        allowedWriteIdentifiers: {},
        activeSession: false,
        profileVerifiedForHardware: false,
      );
      expect(
        guard.evaluate(readFrame, TransmissionPurpose.documentedRead).allowed,
        isFalse,
      );
    });
    test('allows only declared read identifiers', () {
      const guard = TransmissionGuard(
        allowedReadIdentifiers: {0x301},
        allowedWriteIdentifiers: {},
        activeSession: true,
        profileVerifiedForHardware: false,
      );
      expect(
        guard.evaluate(readFrame, TransmissionPurpose.documentedRead).allowed,
        isTrue,
      );
      expect(
        guard
            .evaluate(
              const BusFrame(identifier: 0x777, payload: []),
              TransmissionPurpose.documentedRead,
            )
            .allowed,
        isFalse,
      );
    });
    test('write stays blocked without hardware verification', () {
      const guard = TransmissionGuard(
        allowedReadIdentifiers: {},
        allowedWriteIdentifiers: {0x401},
        activeSession: true,
        profileVerifiedForHardware: false,
      );
      expect(
        guard
            .evaluate(
              const BusFrame(identifier: 0x401, payload: [1]),
              TransmissionPurpose.verifiedParameterWrite,
            )
            .allowed,
        isFalse,
      );
    });
  });
}
