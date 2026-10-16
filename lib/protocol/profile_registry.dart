import 'dart:convert';
import 'package:flutter/services.dart';
import 'device_profile.dart';

class ProfileRegistry {
  ProfileRegistry._(this._profiles);
  final Map<String, DeviceProfile> _profiles;
  Iterable<DeviceProfile> get profiles => _profiles.values;
  DeviceProfile? byId(String id) => _profiles[id];

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
    return ProfileRegistry._(profiles);
  }

  static Future<ProfileRegistry> loadBundledSimulator() async =>
      fromJsonDocuments([
        await rootBundle.loadString(
          'device_profiles/batteries/_simulated/solardiag_sim.json',
        ),
      ], technicianMode: true);
}
