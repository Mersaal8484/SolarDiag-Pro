enum DataAbsenceReason { notSupported, notReported, readFailed, stale }

enum MeasurementQuality { good, uncertain, stale, unavailable }

enum VerificationStatus {
  unsupported,
  verifiedHardware,
  verifiedDocument,
  communitySourced,
  researchTarget,
  simulated,
  studioDraft,
}

enum TemperatureSensorKind { cell, mosfet, ambient, terminal }

class Measurement {
  const Measurement.value(
    this.value,
    this.unit, {
    this.timestamp,
    this.quality = MeasurementQuality.good,
  }) : absenceReason = null;
  const Measurement.absent(this.absenceReason, {this.unit, this.timestamp})
    : value = null,
      quality = MeasurementQuality.unavailable;
  final double? value;
  final String? unit;
  final DateTime? timestamp;
  final MeasurementQuality quality;
  final DataAbsenceReason? absenceReason;
  bool get isReported => value != null;
  Duration? ageAt(DateTime now) =>
      timestamp == null ? null : now.difference(timestamp!);
  bool isStaleAt(DateTime now, Duration interval) =>
      !isReported ||
      quality == MeasurementQuality.stale ||
      (ageAt(now)?.compareTo(interval) ?? 1) > 0;
}

class TemperatureReading {
  const TemperatureReading({
    required this.label,
    required this.kind,
    required this.measurement,
  });
  final String label;
  final TemperatureSensorKind kind;
  final Measurement measurement;
}

class TelemetrySnapshot {
  const TelemetrySnapshot({
    required this.voltage,
    required this.current,
    required this.power,
    required this.soc,
    required this.soh,
    required this.remainingCapacity,
    required this.fullChargeCapacity,
    required this.cycleCount,
    required this.cellMeasurements,
    required this.temperatureSensors,
    required this.chargeMosfet,
    required this.dischargeMosfet,
    required this.contactor,
    required this.balancingMask,
    required this.chargeCurrentLimit,
    required this.dischargeCurrentLimit,
    required this.chargeVoltageLimit,
    required this.rawAlarmBits,
    required this.rawProtectionBits,
    required this.linkStatus,
    required this.timestamp,
    required this.staleAfter,
  });
  final Measurement voltage;
  final Measurement current;
  final Measurement power;
  final Measurement soc;
  final Measurement soh;
  final Measurement remainingCapacity;
  final Measurement fullChargeCapacity;
  final Measurement cycleCount;
  final List<Measurement> cellMeasurements;
  final List<TemperatureReading> temperatureSensors;
  final Measurement chargeMosfet;
  final Measurement dischargeMosfet;
  final Measurement contactor;
  final Measurement balancingMask;
  final Measurement chargeCurrentLimit;
  final Measurement dischargeCurrentLimit;
  final Measurement chargeVoltageLimit;
  final Measurement rawAlarmBits;
  final Measurement rawProtectionBits;
  final Measurement linkStatus;
  final DateTime timestamp;
  final Duration staleAfter;

  List<double> get cellVoltages => [
    for (final cell in cellMeasurements) ?cell.value,
  ];
  Measurement get temperature => temperatureSensors.isEmpty
      ? const Measurement.absent(DataAbsenceReason.notReported, unit: '°C')
      : temperatureSensors.first.measurement;
  double? get cellDelta {
    final cells = cellVoltages;
    if (cells.length < 2) return null;
    final sorted = [...cells]..sort();
    return sorted.last - sorted.first;
  }

  bool get isStale => [
    voltage,
    current,
    soc,
    linkStatus,
  ].any((value) => value.isStaleAt(timestamp, staleAfter));
}

typedef BatterySnapshot = TelemetrySnapshot;
