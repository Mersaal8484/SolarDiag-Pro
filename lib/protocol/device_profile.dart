import '../core/battery_models.dart';
import 'capabilities.dart';

enum InterfaceType { can, rs485, rs232, uart, ble, simulator, ethernet }

class TransportRequirement {
  const TransportRequirement({
    required this.interfaceType,
    this.bitrate,
    this.baudRate,
    this.supportedBaudRates = const [],
    this.dataFormats = const [],
    required this.listenOnlyByDefault,
  });
  final InterfaceType interfaceType;
  final int? bitrate;
  final int? baudRate;
  final List<int> supportedBaudRates;
  final List<String> dataFormats;
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

class LocalizedText {
  const LocalizedText({required this.en, required this.ar});
  final String en;
  final String ar;
  static LocalizedText fromJson(Object? value, String path) {
    if (value is! Map<String, Object?> ||
        value['en'] is! String ||
        (value['en'] as String).trim().isEmpty ||
        value['ar'] is! String ||
        (value['ar'] as String).trim().isEmpty) {
      throw FormatException('$path must contain non-empty en and ar text.');
    }
    return LocalizedText(en: value['en'] as String, ar: value['ar'] as String);
  }
}

class TelemetryFieldDefinition {
  const TelemetryFieldDefinition({
    required this.id,
    required this.label,
    required this.source,
    this.unit,
    this.scale = 1,
  });
  final String id;
  final LocalizedText label;
  final Map<String, Object?> source;
  final String? unit;
  final num scale;
}

enum ParameterAccess {
  readOnly,
  readWrite,
  writeOnly,
  calibrate,
  factory;

  static ParameterAccess from(String raw) => fromString(raw);
  static ParameterAccess fromString(String raw) => switch (raw.toLowerCase()) {
    'readonly' || 'read_only' || 'read' => ParameterAccess.readOnly,
    'readwrite' ||
    'read_write' ||
    'simulated-write' => ParameterAccess.readWrite,
    'writeonly' || 'write_only' || 'write' => ParameterAccess.writeOnly,
    'calibrate' => ParameterAccess.calibrate,
    'factory' => ParameterAccess.factory,
    _ => throw FormatException('Unknown parameter access: $raw'),
  };
}

class ProfileApproval {
  const ProfileApproval({
    required this.lifecycleStage,
    required this.approvedByRole,
    this.hardwareValidationRecordId = '',
    this.verifiedCapabilities = const [],
    this.approvedAt,
  });

  final String lifecycleStage;
  final String approvedByRole;
  final String hardwareValidationRecordId;
  final List<String> verifiedCapabilities;
  final DateTime? approvedAt;

  factory ProfileApproval.fromJson(Map<String, Object?> json) =>
      ProfileApproval(
        lifecycleStage: json['lifecycle_stage'] as String? ?? '',
        approvedByRole: json['approved_by_role'] as String? ?? '',
        hardwareValidationRecordId:
            json['hardware_validation_record_id'] as String? ?? '',
        verifiedCapabilities: [
          for (final cap
              in (json['verified_capabilities'] as List? ?? const []))
            cap.toString(),
        ],
      );

  bool isApprovedFor(DeviceCapability capability) {
    if (lifecycleStage != 'published' || approvedByRole != 'approvalEngineer') {
      return false;
    }
    return verifiedCapabilities.contains(capability.name);
  }
}

class ProfileParameterDefinition {
  const ProfileParameterDefinition({
    required this.id,
    required this.label,
    required this.access,
    required this.definition,
  });
  final String id;
  final LocalizedText label;
  final ParameterAccess access;
  final Map<String, Object?> definition;
}

class DeviceProfile {
  const DeviceProfile({
    required this.schemaVersion,
    required this.id,
    required this.category,
    required this.manufacturer,
    required this.family,
    required this.models,
    required this.firmwareRanges,
    required this.provenance,
    required this.transport,
    required this.capabilities,
    required this.allowedReadFrames,
    required this.allowedModbusReadRanges,
    required this.telemetryMap,
    required this.alarmDictionary,
    required this.parameters,
    required this.topology,
    required this.inverterLink,
    required this.testVectors,
    required this.connectionChecklist,
    required this.simulated,
    this.approval,
  });
  final int schemaVersion;
  final String id;
  final String category;
  final String manufacturer;
  final String family;
  final List<String> models;
  final List<String> firmwareRanges;
  final Provenance provenance;
  final TransportRequirement transport;
  final CapabilitySet capabilities;
  final Set<int> allowedReadFrames;
  final List<Map<String, int>> allowedModbusReadRanges;
  final List<TelemetryFieldDefinition> telemetryMap;
  final Map<String, LocalizedText> alarmDictionary;
  final List<ProfileParameterDefinition> parameters;
  final Map<String, Object?> topology;
  final Map<String, Object?> inverterLink;
  final List<Map<String, Object?>> testVectors;
  final List<LocalizedText> connectionChecklist;
  final bool simulated;
  final ProfileApproval? approval;

  /// يُحدَّد `hasWriteCapability` بحيث يكون صحيحاً إذا كانت أي قدرة كتابة أو معايرة
  /// مدعومة (ليست unsupported)، أو إذا كان أي معامل يتطلب وصولاً غير readOnly.
  /// هذا يضمن عدم تخطي مرحلة مراجعة السلامة لأي مساهمة تحتوي قدرة كتابة محتملة.
  bool get hasWriteCapability {
    const writeCapabilities = [
      DeviceCapability.writeParameter,
      DeviceCapability.calibrate,
    ];
    final hasCap = writeCapabilities.any(
      (cap) =>
          capabilities.statusOf(cap) == VerificationStatus.verifiedHardware,
    );
    final hasParamWrite = parameters.any(
      (p) => p.access != ParameterAccess.readOnly,
    );
    return hasCap || hasParamWrite;
  }

  static Map<String, Object?> migrateV1ToV2(Map<String, Object?> source) =>
      source['schema_version'] != 1
      ? Map.of(source)
      : <String, Object?>{
          ...source,
          'schema_version': 2,
          'category': source['category'] ?? 'battery',
          'telemetry_map': source['telemetry_map'] ?? <Object?>[],
          'alarm_dictionary': source['alarm_dictionary'] ?? <String, Object?>{},
          'parameters': source['parameters'] ?? <Object?>[],
          'topology': source['topology'] ?? <String, Object?>{},
          'inverter_link': source['inverter_link'] ?? <String, Object?>{},
          'test_vectors': source['test_vectors'] ?? <Object?>[],
          'connection_checklist': source['connection_checklist'] ?? <Object?>[],
          'allowed_modbus_read_ranges':
              source['allowed_modbus_read_ranges'] ?? <Object?>[],
        };

  static DeviceProfile fromJson(Map<String, Object?> source) {
    final json = source['schema_version'] == 1 ? migrateV1ToV2(source) : source;
    if (json['schema_version'] != 2) {
      throw const FormatException('Unsupported profile schema version.');
    }
    String requiredString(String key) => _requiredString(json, key);
    final provenanceJson = _map(json['provenance'], 'provenance');
    final transportJson = _map(json['transport'], 'transport');
    final capabilityJson = _map(json['capabilities'], 'capabilities');
    final statuses = <DeviceCapability, VerificationStatus>{};
    for (final capability in DeviceCapability.values) {
      final raw = capabilityJson[_capabilityKey(capability)];
      if (raw is String) {
        statuses[capability] = VerificationStatus.values.byName(raw);
      }
    }
    final simulated = json['simulated'] == true;
    final profileId = requiredString('id');
    final transportInterface = transportJson['interface'] as String? ?? '';
    if (simulated) {
      if (!profileId.startsWith('solardiag.simulated.')) {
        throw const FormatException(
          'Simulated profiles must have an id starting with "solardiag.simulated."',
        );
      }
      if (transportInterface != 'simulator') {
        throw const FormatException(
          'Simulated profiles must use the simulator transport interface.',
        );
      }
    }
    if (!simulated && statuses.values.contains(VerificationStatus.simulated)) {
      throw const FormatException(
        'Physical profiles cannot declare simulated capabilities.',
      );
    }
    final ranges =
        _maps(
          json['allowed_modbus_read_ranges'],
          'allowed_modbus_read_ranges',
        ).map((range) {
          final start = range['start'];
          final end = range['end'];
          if (start is! int || end is! int || start < 0 || end < start) {
            throw const FormatException('Invalid Modbus read range.');
          }
          return <String, int>{'start': start, 'end': end};
        }).toList();
    final telemetry = _maps(json['telemetry_map'], 'telemetry_map')
        .map(
          (item) => TelemetryFieldDefinition(
            id: _requiredString(item, 'id'),
            label: LocalizedText.fromJson(item['label'], 'telemetry label'),
            source: _map(item['source'], 'telemetry source'),
            unit: item['unit'] as String?,
            scale: item['scale'] as num? ?? 1,
          ),
        )
        .toList();
    final alarms = <String, LocalizedText>{};
    for (final entry in _map(
      json['alarm_dictionary'],
      'alarm_dictionary',
    ).entries) {
      alarms[entry.key] = LocalizedText.fromJson(
        entry.value,
        'alarm ${entry.key}',
      );
    }
    final parameters = _maps(json['parameters'], 'parameters')
        .map(
          (item) => ProfileParameterDefinition(
            id: _requiredString(item, 'id'),
            label: LocalizedText.fromJson(item['label'], 'parameter label'),
            access: ParameterAccess.fromString(_requiredString(item, 'access')),
            definition: item,
          ),
        )
        .toList();
    final readFrames = json['allowed_read_frames'];
    if (readFrames is! List || readFrames.any((value) => value is! int)) {
      throw const FormatException('allowed_read_frames must contain integers.');
    }
    final baudRates = transportJson['baud_rates'];
    if (baudRates != null &&
        (baudRates is! List || baudRates.any((v) => v is! int))) {
      throw const FormatException('baud_rates must contain integers.');
    }
    final checklist = json['connection_checklist'];
    if (checklist is! List) {
      throw const FormatException('connection_checklist must be an array.');
    }
    final approvalJson = json['approval'];
    final approval = approvalJson is Map<String, Object?>
        ? ProfileApproval.fromJson(approvalJson)
        : null;
    return DeviceProfile(
      schemaVersion: 2,
      id: profileId,
      category: requiredString('category'),
      manufacturer: requiredString('manufacturer'),
      family: requiredString('family'),
      models: _nonEmptyStrings(json['models'], 'models'),
      firmwareRanges: _nonEmptyStrings(
        json['firmware_ranges'],
        'firmware_ranges',
      ),
      provenance: Provenance(
        source: _requiredString(provenanceJson, 'source'),
        documentId: _requiredString(provenanceJson, 'document_id'),
        retrievedOn: DateTime.parse(
          _requiredString(provenanceJson, 'retrieved_on'),
        ),
        verifiedBy: _requiredString(provenanceJson, 'verified_by'),
      ),
      transport: TransportRequirement(
        interfaceType: InterfaceType.values.byName(
          _requiredString(transportJson, 'interface'),
        ),
        bitrate: transportJson['bitrate'] as int?,
        baudRate: transportJson['baud_rate'] as int?,
        supportedBaudRates: baudRates == null
            ? const []
            : (baudRates as List).cast<int>(),
        dataFormats: _strings(
          transportJson['data_formats'] ?? const [],
          'data_formats',
        ),
        listenOnlyByDefault: transportJson['listen_only_default'] == true,
      ),
      capabilities: CapabilitySet(statuses),
      allowedReadFrames: readFrames.cast<int>().toSet(),
      allowedModbusReadRanges: ranges,
      telemetryMap: telemetry,
      alarmDictionary: alarms,
      parameters: parameters,
      topology: _map(json['topology'], 'topology'),
      inverterLink: _map(json['inverter_link'], 'inverter_link'),
      testVectors: _maps(json['test_vectors'], 'test_vectors'),
      connectionChecklist: checklist
          .map(
            (item) => LocalizedText.fromJson(item, 'connection checklist item'),
          )
          .toList(),
      simulated: simulated,
      approval: approval,
    );
  }

  static Map<String, Object?> _map(Object? value, String name) {
    if (value is! Map<String, Object?>) {
      throw FormatException('$name must be an object.');
    }
    return value;
  }

  static List<Map<String, Object?>> _maps(Object? value, String name) {
    if (value is! List || value.any((item) => item is! Map<String, Object?>)) {
      throw FormatException('$name must be an object array.');
    }
    return value.cast<Map<String, Object?>>();
  }

  static List<String> _strings(Object? value, String name) {
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('$name must be a string array.');
    }
    return value.cast<String>();
  }

  static List<String> _nonEmptyStrings(Object? value, String name) {
    final values = _strings(value, name);
    if (values.isEmpty) throw FormatException('$name cannot be empty.');
    return values;
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
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
