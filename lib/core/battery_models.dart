enum DataAbsenceReason { notSupported, notReported, readFailed, stale }

enum VerificationStatus {
  verifiedHardware,
  verifiedDocument,
  communitySourced,
  researchTarget,
  simulated,
  studioDraft,
}

class Measurement {
  const Measurement.value(this.value, this.unit) : absenceReason = null;
  const Measurement.absent(this.absenceReason) : value = null, unit = null;
  final double? value;
  final String? unit;
  final DataAbsenceReason? absenceReason;
  bool get isReported => value != null;
}

class BatterySnapshot {
  const BatterySnapshot({
    required this.voltage,
    required this.current,
    required this.soc,
    required this.temperature,
    required this.cellVoltages,
    required this.timestamp,
  });
  final Measurement voltage;
  final Measurement current;
  final Measurement soc;
  final Measurement temperature;
  final List<double> cellVoltages;
  final DateTime timestamp;
  double? get cellDelta {
    if (cellVoltages.length < 2) return null;
    final sorted = [...cellVoltages]..sort();
    return sorted.last - sorted.first;
  }
}
