import 'dart:convert';
import '../core/battery_models.dart';
import '../simulator/simulated_profile_document.dart';
import '../trust/profile_integrity.dart';
import 'capabilities.dart';
import 'device_profile.dart';

class ProfileRegistry {
  ProfileRegistry._(this._profiles, this._writeCapabilities);
  factory ProfileRegistry.empty() => ProfileRegistry._({}, {});

  final Map<String, DeviceProfile> _profiles;
  final Map<String, Set<DeviceCapability>> _writeCapabilities;
  Iterable<DeviceProfile> get profiles => _profiles.values;
  DeviceProfile? byId(String id) => _profiles[id];

  bool canWrite(
    String id, [
    DeviceCapability capability = DeviceCapability.writeParameter,
  ]) => profileCanWrite(id, capability);

  bool profileCanWrite(
    String id, [
    DeviceCapability capability = DeviceCapability.writeParameter,
  ]) => _writeCapabilities[id]?.contains(capability) ?? false;

  static ProfileRegistry fromJsonDocuments(
    Iterable<String> documents, {
    required bool technicianMode,
  }) => _fromJsonDocuments(
    documents,
    technicianMode: technicianMode,
    isBundled: false,
  );

  static ProfileRegistry _fromJsonDocuments(
    Iterable<String> documents, {
    required bool technicianMode,
    required bool isBundled,
  }) {
    final profiles = <String, DeviceProfile>{};
    for (final document in documents) {
      final decoded = jsonDecode(document);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Profile root must be an object.');
      }
      final profile = DeviceProfile.fromJson(decoded);
      if (!isBundled && profile.simulated) {
        throw const FormatException(
          'Unsigned simulated profiles must be loaded from bundled assets or signed documents.',
        );
      }
      if (technicianMode && !profile.simulated) {
        throw const FormatException(
          'Unsigned physical profiles are blocked in technician mode.',
        );
      }
      if (profiles.containsKey(profile.id)) {
        throw FormatException('Duplicate profile id: ${profile.id}');
      }
      profiles[profile.id] = profile;
    }
    return ProfileRegistry._(profiles, const {});
  }

  static Future<ProfileRegistry> fromSignedDocuments(
    Iterable<SignedProfileDocument> documents, {
    required Ed25519TrustVerifier verifier,
    required bool technicianMode,
    bool developerMode = false,
  }) async {
    final accepted = <String>[];
    final writeCapabilities = <String, Set<DeviceCapability>>{};
    for (final signed in documents) {
      final decoded = jsonDecode(signed.document);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Profile root must be an object.');
      }
      final profile = DeviceProfile.fromJson(decoded);
      final trusted = await verifier.verifyProfile(signed);
      if (!trusted && technicianMode && !profile.simulated) {
        throw const FormatException(
          'Unsigned or invalid physical profile blocked in technician mode.',
        );
      }
      if (!trusted && !developerMode && !profile.simulated) {
        throw const FormatException('Untrusted physical profile blocked.');
      }
      if (trusted && !profile.simulated) {
        final approval = profile.approval;
        if (approval != null &&
            approval.lifecycleStage == 'published' &&
            approval.approvedByRole == 'approvalEngineer') {
          final allowedCaps = <DeviceCapability>{};
          for (final cap in [
            DeviceCapability.writeParameter,
            DeviceCapability.calibrate,
          ]) {
            if (profile.capabilities.statusOf(cap) ==
                    VerificationStatus.verifiedHardware &&
                approval.isApprovedFor(cap)) {
              allowedCaps.add(cap);
            }
          }
          if (allowedCaps.isNotEmpty) {
            writeCapabilities[profile.id] = allowedCaps;
          }
        }
      }
      accepted.add(signed.document);
    }
    final registry = _fromJsonDocuments(
      accepted,
      technicianMode: false,
      isBundled: true,
    );
    return ProfileRegistry._(
      registry._profiles,
      Map.unmodifiable(writeCapabilities),
    );
  }

  static Future<ProfileRegistry> loadBundledSimulator() async =>
      _fromJsonDocuments(
        [simulatedProfileDocument],
        technicianMode: true,
        isBundled: true,
      );
}
