import '../protocol/device_profile.dart';
import '../core/battery_models.dart';

const gatewayProtocolVersion = 1;
const standardCanBitrates = <int>{125000, 250000, 500000, 1000000};

enum GatewayOperatingMode { listenOnly, activeRead, write }

class GatewayInterfaceDescriptor {
  const GatewayInterfaceDescriptor({
    required this.type,
    required this.isolated,
    required this.listenOnlyCapable,
    this.activeReadCapable = true,
    this.writeCapable = true,
    this.bitrates = const {},
    this.validatedCustomBitrates = const {},
    this.baudRates = const {},
  });

  final InterfaceType type;
  final bool isolated;
  final bool listenOnlyCapable;
  final bool activeReadCapable;
  final bool writeCapable;
  final Set<int> bitrates;
  final Set<int> validatedCustomBitrates;
  final Set<int> baudRates;

  bool supportsBitrate(int bitrate) =>
      bitrates.contains(bitrate) &&
      (standardCanBitrates.contains(bitrate) ||
          validatedCustomBitrates.contains(bitrate));

  factory GatewayInterfaceDescriptor.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String) {
      throw const FormatException('Gateway interface type is required.');
    }
    final interfaceType = InterfaceType.values.byName(type);
    final bitrates = _integerSet(json['bitrates'], 'bitrates');
    final validatedCustomBitrates = _integerSet(
      json['validated_custom_bitrates'],
      'validated_custom_bitrates',
    );
    if (validatedCustomBitrates.any(
      (bitrate) =>
          standardCanBitrates.contains(bitrate) || !bitrates.contains(bitrate),
    )) {
      throw const FormatException(
        'Validated custom bitrates must be declared non-standard bitrates.',
      );
    }
    if (interfaceType == InterfaceType.can &&
        !bitrates.containsAll(standardCanBitrates)) {
      throw const FormatException(
        'CAN capability announcement must declare every standard bitrate.',
      );
    }
    return GatewayInterfaceDescriptor(
      type: interfaceType,
      isolated: json['isolated'] == true,
      listenOnlyCapable: json['listen_only_capable'] == true,
      activeReadCapable: json['active_read_capable'] != false,
      writeCapable: json['write_capable'] != false,
      bitrates: bitrates,
      validatedCustomBitrates: validatedCustomBitrates,
      baudRates: _integerSet(json['baud_rates'], 'baud_rates'),
    );
  }

  static Set<int> _integerSet(Object? value, String field) {
    if (value == null) return const {};
    if (value is! List || value.any((item) => item is! int || item <= 0)) {
      throw FormatException('$field must contain positive integers.');
    }
    return value.cast<int>().toSet();
  }
}

class GatewayDescriptor {
  const GatewayDescriptor({
    required this.protocolVersion,
    required this.hardwareRevision,
    required this.firmwareVersion,
    required this.bootId,
    required this.physicalTxInterlock,
    required this.interfaces,
  });

  final int protocolVersion;
  final String hardwareRevision;
  final String firmwareVersion;
  final String bootId;
  final bool physicalTxInterlock;
  final List<GatewayInterfaceDescriptor> interfaces;

  factory GatewayDescriptor.fromJson(Map<String, Object?> json) {
    String requiredString(String field) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('$field must be a non-empty string.');
      }
      return value;
    }

    final rawInterfaces = json['interfaces'];
    if (rawInterfaces is! List || rawInterfaces.isEmpty) {
      throw const FormatException('Gateway must declare its interfaces.');
    }
    return GatewayDescriptor(
      protocolVersion: json['protocol_version'] as int? ?? -1,
      hardwareRevision: requiredString('hardware_revision'),
      firmwareVersion: requiredString('firmware_version'),
      bootId: requiredString('boot_id'),
      physicalTxInterlock: json['physical_tx_interlock'] == true,
      interfaces: rawInterfaces
          .map((item) {
            if (item is! Map<String, Object?>) {
              throw const FormatException('Invalid gateway interface entry.');
            }
            return GatewayInterfaceDescriptor.fromJson(item);
          })
          .toList(growable: false),
    );
  }
}

class GatewaySessionPlan {
  const GatewaySessionPlan({
    required this.interfaceType,
    required this.mode,
    this.bitrate,
    this.baudRate,
    this.maxFramesPerSecond = 0,
    this.busLoadCap = 0,
  });

  final InterfaceType interfaceType;
  final GatewayOperatingMode mode;
  final int? bitrate;
  final int? baudRate;
  final int maxFramesPerSecond;
  final double busLoadCap;

  bool get transmissionEnabled => mode != GatewayOperatingMode.listenOnly;
}

class Rs485AllowListEntry {
  const Rs485AllowListEntry({
    required this.unitAddress,
    required this.functionCode,
  }) : assert(unitAddress >= 0 && unitAddress <= 247),
       assert(functionCode > 0 && functionCode <= 255);

  final int unitAddress;
  final int functionCode;

  @override
  bool operator ==(Object other) =>
      other is Rs485AllowListEntry &&
      other.unitAddress == unitAddress &&
      other.functionCode == functionCode;

  @override
  int get hashCode => Object.hash(unitAddress, functionCode);
}

class GatewayTransmissionRequest {
  const GatewayTransmissionRequest.can(int identifier)
    : interfaceType = InterfaceType.can,
      canIdentifier = identifier,
      rs485Request = null;

  GatewayTransmissionRequest.rs485({
    required int unitAddress,
    required int functionCode,
  }) : interfaceType = InterfaceType.rs485,
       canIdentifier = null,
       rs485Request = Rs485AllowListEntry(
         unitAddress: unitAddress,
         functionCode: functionCode,
       );

  final InterfaceType interfaceType;
  final int? canIdentifier;
  final Rs485AllowListEntry? rs485Request;
}

class GatewayTransmissionContractDecision {
  const GatewayTransmissionContractDecision._({
    required this.allowed,
    required this.auditAction,
    required this.reason,
  });

  const GatewayTransmissionContractDecision.allow()
    : this._(
        allowed: true,
        auditAction: 'tx_allowlist_accept',
        reason: 'allow-listed',
      );

  const GatewayTransmissionContractDecision.drop(String reason)
    : this._(allowed: false, auditAction: 'tx_allowlist_drop', reason: reason);

  final bool allowed;
  final String auditAction;
  final String reason;
  bool get dropped => !allowed;
}

class GatewayTransmissionAllowList {
  const GatewayTransmissionAllowList({
    this.canIdentifiers = const {},
    this.rs485Requests = const {},
  });

  final Set<int> canIdentifiers;
  final Set<Rs485AllowListEntry> rs485Requests;

  GatewayTransmissionContractDecision evaluate(
    GatewayTransmissionRequest request,
  ) {
    final allowed = switch (request.interfaceType) {
      InterfaceType.can => canIdentifiers.contains(request.canIdentifier),
      InterfaceType.rs485 => rs485Requests.contains(request.rs485Request),
      _ => false,
    };
    return allowed
        ? const GatewayTransmissionContractDecision.allow()
        : GatewayTransmissionContractDecision.drop(
            '${request.interfaceType.name} request is not allow-listed.',
          );
  }
}

class GatewayTransmissionAuditRecord {
  const GatewayTransmissionAuditRecord({
    required this.interfaceType,
    required this.action,
    required this.reason,
  });

  final InterfaceType interfaceType;
  final String action;
  final String reason;
}

class GatewayTransmissionContract {
  GatewayTransmissionContract(this.allowList);

  final GatewayTransmissionAllowList allowList;
  final List<GatewayTransmissionAuditRecord> _auditRecords = [];

  List<GatewayTransmissionAuditRecord> get auditRecords =>
      List.unmodifiable(_auditRecords);

  GatewayTransmissionContractDecision evaluate(
    GatewayTransmissionRequest request,
  ) {
    final decision = allowList.evaluate(request);
    _auditRecords.add(
      GatewayTransmissionAuditRecord(
        interfaceType: request.interfaceType,
        action: decision.auditAction,
        reason: decision.reason,
      ),
    );
    return decision;
  }
}

class GatewayContractException implements Exception {
  const GatewayContractException(this.message);
  final String message;

  @override
  String toString() => 'GatewayContractException: $message';
}

class GatewaySessionNegotiator {
  const GatewaySessionNegotiator();

  GatewaySessionPlan negotiatePassive(
    GatewayDescriptor gateway,
    TransportRequirement requirement,
  ) {
    if (gateway.protocolVersion != gatewayProtocolVersion) {
      throw const GatewayContractException(
        'Unsupported gateway protocol version.',
      );
    }
    if (!gateway.physicalTxInterlock) {
      throw const GatewayContractException(
        'Gateway does not declare a physical TX interlock.',
      );
    }
    final matches = gateway.interfaces.where(
      (candidate) => candidate.type == requirement.interfaceType,
    );
    if (matches.length != 1) {
      throw const GatewayContractException(
        'Required interface is absent or declared more than once.',
      );
    }
    final interface = matches.single;
    if (!interface.isolated) {
      throw const GatewayContractException('Interface is not isolated.');
    }
    if (!interface.listenOnlyCapable || !requirement.listenOnlyByDefault) {
      throw const GatewayContractException(
        'Passive sessions require listen-only support and policy.',
      );
    }
    if (requirement.bitrate != null &&
        !interface.supportsBitrate(requirement.bitrate!)) {
      throw const GatewayContractException('Required bitrate is unsupported.');
    }
    if (requirement.baudRate != null &&
        !interface.baudRates.contains(requirement.baudRate)) {
      throw const GatewayContractException(
        'Required baud rate is unsupported.',
      );
    }
    return GatewaySessionPlan(
      interfaceType: requirement.interfaceType,
      mode: GatewayOperatingMode.listenOnly,
      bitrate: requirement.bitrate,
      baudRate: requirement.baudRate,
    );
  }

  GatewaySessionPlan negotiateActiveRead(
    GatewayDescriptor gateway,
    TransportRequirement requirement, {
    required VerificationStatus capabilityStatus,
    required bool explicitlyStarted,
    required int maxFramesPerSecond,
    required double busLoadCap,
    bool highVoltageBattery = false,
  }) {
    final passive = negotiatePassive(gateway, requirement);
    final interface = gateway.interfaces.firstWhere(
      (candidate) => candidate.type == requirement.interfaceType,
    );
    if (!interface.activeReadCapable) {
      throw const GatewayContractException(
        'Gateway interface does not declare active-read support.',
      );
    }
    final verified =
        capabilityStatus == VerificationStatus.verifiedDocument ||
        capabilityStatus == VerificationStatus.verifiedHardware;
    if (highVoltageBattery &&
        capabilityStatus != VerificationStatus.verifiedHardware) {
      throw const GatewayContractException(
        'High-voltage battery sessions remain monitoring-only without verified hardware.',
      );
    }
    if (!verified ||
        !explicitlyStarted ||
        maxFramesPerSecond <= 0 ||
        busLoadCap <= 0 ||
        busLoadCap > 1) {
      throw const GatewayContractException(
        'Active read requires verified capability, consent, and declared limits.',
      );
    }
    return GatewaySessionPlan(
      interfaceType: passive.interfaceType,
      mode: GatewayOperatingMode.activeRead,
      bitrate: passive.bitrate,
      baudRate: passive.baudRate,
      maxFramesPerSecond: maxFramesPerSecond,
      busLoadCap: busLoadCap,
    );
  }

  GatewaySessionPlan negotiateWrite(
    GatewayDescriptor gateway,
    TransportRequirement requirement, {
    required bool writeVerifiedOnHardware,
    required bool explicitlyStarted,
  }) {
    final passive = negotiatePassive(gateway, requirement);
    final interface = gateway.interfaces.firstWhere(
      (candidate) => candidate.type == requirement.interfaceType,
    );
    if (!interface.writeCapable) {
      throw const GatewayContractException(
        'Gateway interface does not declare write support.',
      );
    }
    if (!writeVerifiedOnHardware || !explicitlyStarted) {
      throw const GatewayContractException(
        'Write mode requires verified hardware capability and explicit start.',
      );
    }
    return GatewaySessionPlan(
      interfaceType: passive.interfaceType,
      mode: GatewayOperatingMode.write,
      bitrate: passive.bitrate,
      baudRate: passive.baudRate,
    );
  }
}
