import '../core/battery_models.dart';
import 'capabilities.dart';

enum InterfaceType { can, rs485, rs232, uart, ble, simulator }

class TransportRequirement {
  const TransportRequirement({
    required this.interfaceType,
    this.bitrate,
    this.baudRate,
    required this.listenOnlyByDefault,
  });
  final InterfaceType interfaceType;
  final int? bitrate;
  final int? baudRate;
  final bool listenOnlyByDefault;
}

class Provenance {
  const Provenance({
    required this.source,
    required this.documentId,
    required this.retrievedOn,
    required this.verifiedBy,
  });
  final String source;
  final String documentId;
  final DateTime retrievedOn;
  final String verifiedBy;
}

class DeviceProfile {
  const DeviceProfile({
    required this.schemaVersion,
    required this.id,
    required this.manufacturer,
    required this.family,
    required this.models,
    required this.firmwareRanges,
    required this.provenance,
    required this.transport,
    required this.capabilities,
    required this.allowedReadFrames,
    required this.simulated,
  });
  final int schemaVersion;
  final String id;
  final String manufacturer;
  final String family;
  final List<String> models;
  final List<String> firmwareRanges;
  final Provenance provenance;
  final TransportRequirement transport;
  final CapabilitySet capabilities;
  final Set<int> allowedReadFrames;
  final bool simulated;

  static DeviceProfile fromJson(Map<String, Object?> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException(
          'Profile field "$key" must be a non-empty string.',
        );
      }
      return value;
    }

    final schemaVersion = json['schema_version'];
    if (schemaVersion != 1) {
      throw const FormatException('Unsupported profile schema version.');
    }
    final provenanceJson = json['provenance'];
    final transportJson = json['transport'];
    final capabilityJson = json['capabilities'];
    if (provenanceJson is! Map<String, Object?> ||
        transportJson is! Map<String, Object?> ||
        capabilityJson is! Map<String, Object?>) {
      throw const FormatException(
        'Profile is missing structured provenance, transport, or capabilities.',
      );
    }
    final models = _strings(json['models'], 'models');
    final firmwareRanges = _strings(json['firmware_ranges'], 'firmware_ranges');
    if (models.isEmpty || firmwareRanges.isEmpty) {
      throw const FormatException(
        'Models and firmware ranges cannot be empty.',
      );
    }
    final interfaceType = InterfaceType.values.byName(
      _mapString(transportJson, 'interface'),
    );
    final statuses = <DeviceCapability, VerificationStatus>{};
    for (final capability in DeviceCapability.values) {
      final raw = capabilityJson[_capabilityKey(capability)];
      if (raw is String) {
        statuses[capability] = VerificationStatus.values.byName(raw);
      }
    }
    final readFrames = json['allowed_read_frames'];
    if (readFrames is! List || readFrames.any((value) => value is! int)) {
      throw const FormatException(
        'allowed_read_frames must contain integer identifiers.',
      );
    }
    final simulated = json['simulated'] == true;
    if (!simulated && statuses.values.contains(VerificationStatus.simulated)) {
      throw const FormatException(
        'Physical profiles cannot declare simulated capabilities.',
      );
    }
    return DeviceProfile(
      schemaVersion: schemaVersion as int,
      id: requiredString('id'),
      manufacturer: requiredString('manufacturer'),
      family: requiredString('family'),
      models: models,
      firmwareRanges: firmwareRanges,
      provenance: Provenance(
        source: _mapString(provenanceJson, 'source'),
        documentId: _mapString(provenanceJson, 'document_id'),
        retrievedOn: DateTime.parse(_mapString(provenanceJson, 'retrieved_on')),
        verifiedBy: _mapString(provenanceJson, 'verified_by'),
      ),
      transport: TransportRequirement(
        interfaceType: interfaceType,
        bitrate: transportJson['bitrate'] as int?,
        baudRate: transportJson['baud_rate'] as int?,
        listenOnlyByDefault: transportJson['listen_only_default'] == true,
      ),
      capabilities: CapabilitySet(statuses),
      allowedReadFrames: readFrames.cast<int>().toSet(),
      simulated: simulated,
    );
  }

  static List<String> _strings(Object? value, String name) {
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('$name must be a string array.');
    }
    return value.cast<String>();
  }

  static String _mapString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key must be a non-empty string.');
    }
    return value;
  }

  static String _capabilityKey(DeviceCapability capability) =>
      switch (capability) {
        DeviceCapability.identify => 'identify',
        DeviceCapability.readLive => 'read_live',
        DeviceCapability.readConfiguration => 'read_config',
        DeviceCapability.writeParameter => 'write_parameter',
        DeviceCapability.calibrate => 'calibrate',
      };
}
