part of '../parameters/write_pipeline.dart';

class SimulatedInverterAdapter extends SimulatedParameterBackend
    implements InverterAdapter {
  SimulatedInverterAdapter({this.tick = 0});
  int tick;
  final Map<String, num> _parameters = {'output_frequency_limit': 50};
  final Map<int, int> _registers = {0: 540, 1: 102, 2: 2300, 3: 5000};

  @override
  Future<IdentificationResult> identify() async => const IdentificationResult(
    confidence: 1,
    evidence: ['simulator:modbus-inverter'],
    candidateProfileIds: ['solardiag.simulated.inverter.v1'],
  );
  @override
  Future<InverterTelemetrySnapshot> readTelemetry() async {
    final now = DateTime.utc(2026, 1, 1).add(Duration(seconds: tick));
    return InverterTelemetrySnapshot(
      dcVoltage: Measurement.value(54 + tick * .01, 'V', timestamp: now),
      dcCurrent: Measurement.value(10.2, 'A', timestamp: now),
      dcPower: Measurement.value(550.8, 'W', timestamp: now),
      acVoltage: Measurement.value(230, 'V', timestamp: now),
      acCurrent: Measurement.value(2.2, 'A', timestamp: now),
      acPower: Measurement.value(506, 'W', timestamp: now),
      frequency: Measurement.value(50, 'Hz', timestamp: now),
      temperature: Measurement.value(36, '°C', timestamp: now),
      timestamp: now,
    );
  }

  @override
  Future<Set<String>> readAlarms() async => const {};
  @override
  Future<Map<String, num>> readParameters() async =>
      Map.unmodifiable(_parameters);

  @override
  Future<num> readParameter(String id) async => _parameters[id]!;

  @override
  Future<Map<String, num>> readConfiguration() async => Map.of(_parameters);

  @override
  Future<void> applyRawParameter(
    String id,
    int rawValue,
    String idempotencyKey,
  ) async {
    _parameters[id] = rawValue;
  }

  @override
  ParameterTransport parameterTransport() =>
      createSimulatedParameterTransport(this);
  @override
  Future<CapabilitySet> capabilities() async => CapabilitySet({
    for (final value in DeviceCapability.values)
      value: VerificationStatus.simulated,
  });
  @override
  Future<LinkHealth> health() async => const LinkHealth(
    latency: Duration(milliseconds: 8),
    errorRate: 0,
    timeouts: 0,
    crcFailures: 0,
  );

  List<int> respondRtu(List<int> requestBytes) {
    final request = const ModbusRtuCodec().decode(requestBytes);
    if (request.functionCode != ModbusFunction.readHoldingRegisters.code &&
        request.functionCode != ModbusFunction.readInputRegisters.code) {
      return _exception(request, 1);
    }
    if (request.data.length != 4) return _exception(request, 3);
    final start = request.data[0] << 8 | request.data[1];
    final count = request.data[2] << 8 | request.data[3];
    if (count < 1 ||
        count > 125 ||
        List.generate(
          count,
          (i) => start + i,
        ).any((address) => !_registers.containsKey(address))) {
      return _exception(request, 2);
    }
    final data = <int>[count * 2];
    for (var address = start; address < start + count; address++) {
      final value = _registers[address]!;
      data.addAll([value >> 8, value & 0xff]);
    }
    return const ModbusRtuCodec().encode(
      ModbusRtuFrame(
        address: request.address,
        functionCode: request.functionCode,
        data: data,
      ),
    );
  }

  List<int> _exception(ModbusRtuFrame request, int code) {
    final body = [request.address, request.functionCode | 0x80, code];
    final crc = ModbusCrc16.calculate(body);
    return [...body, crc & 0xff, crc >> 8];
  }
}
