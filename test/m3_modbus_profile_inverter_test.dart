import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/protocol/device_profile.dart';
import 'package:solardiag_pro/protocols/modbus/connection_tester.dart';
import 'package:solardiag_pro/protocols/modbus/crc16.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_client.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_guard.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_models.dart';
import 'package:solardiag_pro/protocols/modbus/rtu_codec.dart';
import 'package:solardiag_pro/protocols/modbus/tcp_codec.dart';
import 'package:solardiag_pro/simulator/simulated_inverter_adapter.dart';

void main() {
  group('Modbus codecs', () {
    test('CRC16 matches the standard read example', () {
      expect(ModbusCrc16.calculate([1, 3, 0, 0, 0, 10]), 0xcdc5);
    });

    test('RTU supports all required functions and broadcast write only', () {
      const codec = ModbusRtuCodec();
      for (final function in ModbusFunction.values) {
        final address = function.isWrite ? 0 : 1;
        final encoded = codec.encode(
          ModbusRtuFrame(
            address: address,
            functionCode: function.code,
            data: const [0, 1, 0, 1],
          ),
        );
        final decoded = codec.decode(encoded);
        expect(decoded.functionCode, function.code);
      }
      expect(
        () => codec.encode(
          const ModbusRtuFrame(address: 0, functionCode: 3, data: [0, 0, 0, 1]),
        ),
        throwsFormatException,
      );
    });

    test('RTU stream tolerates noise and partial delivery', () {
      const codec = ModbusRtuCodec();
      final bytes = codec.encode(
        const ModbusRtuFrame(address: 1, functionCode: 3, data: [2, 0, 42]),
      );
      final stream = ModbusRtuStreamDecoder();
      expect(stream.add([99, 88, ...bytes.take(3)]), isEmpty);
      expect(stream.add(bytes.skip(3).toList()).single.data, [2, 0, 42]);
      expect(
        ModbusRtuCodec.interFrameDelay(9600).inMicroseconds,
        greaterThanOrEqualTo(4000),
      );
      expect(ModbusRtuCodec.interFrameDelay(38400).inMicroseconds, 1750);
    });

    test('RTU surfaces protocol exception and timeout', () async {
      final body = [1, 0x83, 2];
      final crc = ModbusCrc16.calculate(body);
      expect(
        () => const ModbusRtuCodec().decode([...body, crc & 0xff, crc >> 8]),
        throwsA(isA<ModbusExceptionResponse>()),
      );
      expect(
        withModbusTimeout(
          Completer<int>().future,
          const Duration(milliseconds: 1),
        ),
        throwsA(isA<ModbusTimeout>()),
      );
    });

    test('TCP validates transaction and MBAP length', () {
      const codec = ModbusTcpCodec();
      final bytes = codec.encode(
        const ModbusTcpFrame(
          transactionId: 7,
          unitId: 1,
          functionCode: 4,
          data: [0, 0, 0, 1],
        ),
      );
      expect(codec.decode(bytes).transactionId, 7);
      expect(() => codec.decode([...bytes, 0]), throwsFormatException);
      final invalidProtocol = [...bytes]..[3] = 1;
      expect(() => codec.decode(invalidProtocol), throwsFormatException);
    });
  });

  test(
    'guard requires ranges, pipeline authorization, and hardware verification',
    () {
      const guarded = ModbusGuard(
        allowedFunctions: {
          ModbusFunction.readHoldingRegisters,
          ModbusFunction.writeSingleRegister,
        },
        readRanges: [RegisterRange(10, 20)],
        writeRanges: [RegisterRange(30, 30)],
        writeVerifiedOnHardware: true,
      );
      expect(
        guarded.allows(
          function: ModbusFunction.readHoldingRegisters,
          address: 10,
          count: 2,
          pipelineAuthorized: false,
        ),
        isTrue,
      );
      expect(
        guarded.allows(
          function: ModbusFunction.writeSingleRegister,
          address: 30,
          count: 1,
          pipelineAuthorized: false,
        ),
        isFalse,
      );
      expect(
        guarded.allows(
          function: ModbusFunction.writeSingleRegister,
          address: 30,
          count: 1,
          pipelineAuthorized: true,
        ),
        isTrue,
      );
    },
  );

  group('profile v2', () {
    test('migrates v1 and rejects missing Arabic localization', () {
      final v2 =
          jsonDecode(
                File(
                  'device_profiles/batteries/_simulated/solardiag_sim.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final v1 = Map<String, Object?>.of(v2)..['schema_version'] = 1;
      expect(DeviceProfile.fromJson(v1).schemaVersion, 2);
      final telemetry =
          (v2['telemetry_map'] as List).first as Map<String, Object?>;
      telemetry['label'] = {'en': 'Voltage'};
      expect(() => DeviceProfile.fromJson(v2), throwsFormatException);
    });

    test('FRECON remains research-only and tester sends no reads', () {
      final json =
          jsonDecode(
                File(
                  'device_profiles/inverters/frecon/pv100_pv200.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final profile = DeviceProfile.fromJson(json);
      expect(profile.telemetryMap, isEmpty);
      expect(profile.allowedModbusReadRanges, isEmpty);
      const guard = ModbusGuard(
        allowedFunctions: {ModbusFunction.readHoldingRegisters},
        readRanges: [],
        writeRanges: [],
        writeVerifiedOnHardware: false,
      );
      final result = const ModbusConnectionTester(guard).inspect();
      expect(result.enabled, isFalse);
      expect(result.message, 'Register map required from manufacturer.');
    });
  });

  test(
    'simulated inverter is deterministic and responds over Modbus',
    () async {
      final inverter = SimulatedInverterAdapter();
      expect((await inverter.identify()).confidence, 1);
      expect((await inverter.readTelemetry()).acVoltage.value, 230);
      final request = const ModbusRtuCodec().encode(
        const ModbusRtuFrame(address: 1, functionCode: 3, data: [0, 0, 0, 2]),
      );
      final response = const ModbusRtuCodec().decode(
        inverter.respondRtu(request),
      );
      expect(response.data, [4, 2, 28, 0, 102]);
    },
  );
}
