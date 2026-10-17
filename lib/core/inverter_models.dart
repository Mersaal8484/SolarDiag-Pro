import 'battery_models.dart';

class InverterTelemetrySnapshot {
  const InverterTelemetrySnapshot({
    required this.dcVoltage,
    required this.dcCurrent,
    required this.dcPower,
    required this.acVoltage,
    required this.acCurrent,
    required this.acPower,
    required this.frequency,
    required this.temperature,
    required this.timestamp,
  });
  final Measurement dcVoltage;
  final Measurement dcCurrent;
  final Measurement dcPower;
  final Measurement acVoltage;
  final Measurement acCurrent;
  final Measurement acPower;
  final Measurement frequency;
  final Measurement temperature;
  final DateTime timestamp;
}
