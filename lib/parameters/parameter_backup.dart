import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'parameter_models.dart';

class ParameterDifference {
  const ParameterDifference({
    required this.parameterId,
    required this.backupValue,
    required this.currentValue,
  });

  final String parameterId;
  final num? backupValue;
  final num? currentValue;
  bool get changed => backupValue != currentValue;
}

class RestorePlan {
  const RestorePlan({
    required this.backup,
    required this.changes,
    required this.orderedDiffHash,
  });

  final ParameterBackup backup;
  final List<ParameterChange> changes;
  final String orderedDiffHash;

  bool get isEmpty => changes.isEmpty;
  bool get isNotEmpty => changes.isNotEmpty;
  int get length => changes.length;
}

class ParameterBackup {
  const ParameterBackup({
    required this.schemaVersion,
    required this.profileId,
    required this.deviceIdentity,
    required this.firmware,
    required this.capturedAt,
    required this.values,
  });
  final int schemaVersion;
  final String profileId;
  final String deviceIdentity;
  final String firmware;
  final DateTime capturedAt;
  final Map<String, num> values;
  String toJson() => jsonEncode({
    'schema_version': schemaVersion,
    'profile_id': profileId,
    'device_identity': deviceIdentity,
    'firmware': firmware,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'values': values,
  });
  static ParameterBackup fromJson(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, Object?> ||
        json['schema_version'] != 1 ||
        json['values'] is! Map) {
      throw const FormatException('Unsupported or malformed parameter backup.');
    }
    final rawValues = json['values']! as Map;
    if (rawValues.values.any((value) => value is! num)) {
      throw const FormatException('Backup values must be numeric.');
    }
    return ParameterBackup(
      schemaVersion: 1,
      profileId: json['profile_id'] as String,
      deviceIdentity: json['device_identity'] as String,
      firmware: json['firmware'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      values: Map.unmodifiable(
        rawValues.map((key, value) => MapEntry(key as String, value as num)),
      ),
    );
  }

  List<ParameterChange> planRestore({
    required String activeProfileId,
    required String activeDeviceIdentity,
    required String activeFirmware,
    required Map<String, ParameterDefinition> definitions,
    required ParameterSnapshot current,
  }) {
    if (activeProfileId != profileId ||
        activeDeviceIdentity != deviceIdentity ||
        activeFirmware != firmware) {
      throw const FormatException(
        'Backup identity or firmware does not match the active device.',
      );
    }
    return [
      for (final entry in values.entries)
        if (current.values[entry.key] != entry.value &&
            definitions.containsKey(entry.key))
          ParameterChange(
            definition: definitions[entry.key]!,
            requestedValue: entry.value,
          ),
    ];
  }

  RestorePlan createRestorePlan({
    required String activeProfileId,
    required String activeDeviceIdentity,
    required String activeFirmware,
    required Map<String, ParameterDefinition> definitions,
    required ParameterSnapshot current,
  }) {
    final changes = planRestore(
      activeProfileId: activeProfileId,
      activeDeviceIdentity: activeDeviceIdentity,
      activeFirmware: activeFirmware,
      definitions: definitions,
      current: current,
    );
    final diffBuffer = changes
        .map((c) => '${c.definition.id}:${c.requestedValue}')
        .join('|');
    final hash = sha256.convert(utf8.encode(diffBuffer)).toString();
    return RestorePlan(
      backup: this,
      changes: changes,
      orderedDiffHash: hash,
    );
  }

  List<ParameterDifference> compare(Map<String, num> currentValues) {
    final ids = {...values.keys, ...currentValues.keys}.toList()..sort();
    return List.unmodifiable([
      for (final id in ids)
        ParameterDifference(
          parameterId: id,
          backupValue: values[id],
          currentValue: currentValues[id],
        ),
    ]);
  }
}
