import 'dart:convert';
import 'package:flutter/services.dart';
import '../trust/profile_integrity.dart';
import 'device_profile.dart';

class ProfileRegistry {
  ProfileRegistry._(this._profiles, this._writeEnabledProfileIds);
  final Map<String, DeviceProfile> _profiles;
  final Set<String> _writeEnabledProfileIds;
  Iterable<DeviceProfile> get profiles => _profiles.values;
  DeviceProfile? byId(String id) => _profiles[id];
  bool profileCanWrite(String id) => _writeEnabledProfileIds.contains(id);

  static ProfileRegistry fromJsonDocuments(
    Iterable<String> documents, {
    required bool technicianMode,
  }) {
    final profiles = <String, DeviceProfile>{};
    for (final document in documents) {
      final decoded = jsonDecode(document);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Profile root must be an object.');
      }
      final profile = DeviceProfile.fromJson(decoded);
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
    final writeEnabled = <String>{};
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
      if (trusted && !profile.simulated && profile.hasWriteCapability) {
        writeEnabled.add(profile.id);
      }
      accepted.add(signed.document);
    }
    final registry = fromJsonDocuments(accepted, technicianMode: false);
    return ProfileRegistry._(
      registry._profiles,
      Set.unmodifiable(writeEnabled),
    );
  }

  static Future<ProfileRegistry> loadBundledSimulator() async =>
      fromJsonDocuments([
        await rootBundle.loadString(
          'device_profiles/batteries/_simulated/solardiag_sim.json',
        ),
      ], technicianMode: true);
}
