import '../core/battery_models.dart';

enum DeviceCapability {
  identify,
  readLive,
  readConfiguration,
  writeParameter,
  calibrate,
}

class CapabilitySet {
  CapabilitySet(Map<DeviceCapability, VerificationStatus> values)
    : _values = Map.unmodifiable(values);
  final Map<DeviceCapability, VerificationStatus> _values;
  VerificationStatus statusOf(DeviceCapability capability) =>
      _values[capability] ?? VerificationStatus.unsupported;
  bool canRead(DeviceCapability capability, {bool expertOptIn = false}) {
    final status = statusOf(capability);
    return status == VerificationStatus.verifiedHardware ||
        status == VerificationStatus.verifiedDocument ||
        status == VerificationStatus.simulated ||
        (expertOptIn && status == VerificationStatus.communitySourced);
  }

  bool canWrite(DeviceCapability capability) =>
      capability == DeviceCapability.writeParameter &&
      statusOf(capability) == VerificationStatus.verifiedHardware;
}
