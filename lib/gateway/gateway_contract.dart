import '../protocol/device_profile.dart';

const gatewayProtocolVersion = 1;

enum GatewayOperatingMode { listenOnly }

class GatewayInterfaceDescriptor {
  const GatewayInterfaceDescriptor({
    required this.type,
    required this.isolated,
    required this.listenOnlyCapable,
    this.bitrates = const {},
    this.baudRates = const {},
  });

  final InterfaceType type;
  final bool isolated;
  final bool listenOnlyCapable;
  final Set<int> bitrates;
  final Set<int> baudRates;

  factory GatewayInterfaceDescriptor.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String) {
      throw const FormatException('Gateway interface type is required.');
    }
    return GatewayInterfaceDescriptor(
      type: InterfaceType.values.byName(type),
      isolated: json['isolated'] == true,
      listenOnlyCapable: json['listen_only_capable'] == true,
      bitrates: _integerSet(json['bitrates'], 'bitrates'),
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
  });

  final InterfaceType interfaceType;
  final GatewayOperatingMode mode;
  final int? bitrate;
  final int? baudRate;

  bool get transmissionEnabled => false;
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
        !interface.bitrates.contains(requirement.bitrate)) {
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
}
