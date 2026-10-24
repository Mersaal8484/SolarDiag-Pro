import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/auth/authorization_controller.dart';
import 'package:solardiag_pro/auth/confirmation_factory.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';
import 'package:solardiag_pro/protocols/modbus/crc16.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_client.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_guard.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_link.dart';
import 'package:solardiag_pro/protocols/modbus/loopback_link.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_models.dart';
import 'package:solardiag_pro/protocols/modbus/rtu_codec.dart';
import 'package:solardiag_pro/protocols/modbus/rtu_link.dart';
import 'package:solardiag_pro/protocols/modbus/tcp_codec.dart';
import 'package:solardiag_pro/protocols/modbus/tcp_link.dart';

class _RecordingLink implements ModbusLink {
  _RecordingLink(this.respond);

  final Future<List<int>> Function(List<int> request) respond;
  final requests = <List<int>>[];

  @override
  Future<List<int>> exchange(
    List<int> request, {
    required Duration timeout,
  }) {
    requests.add(List.unmodifiable(request));
    return respond(request);
  }
}

class _RecordingByteTransport implements ModbusByteTransport {
  _RecordingByteTransport(this.respond);

  final Stream<List<int>> Function(List<int> request) respond;
  final requests = <List<int>>[];

  @override
  Stream<List<int>> exchange(List<int> request) {
    requests.add(List.unmodifiable(request));
    return respond(request);
  }
}

ModbusGuard _readGuard({
  ModbusFunction function = ModbusFunction.readHoldingRegisters,
}) => ModbusGuard(
  allowedFunctions: {function},
  readRanges: const [RegisterRange(0, 10)],
  writeRanges: const [],
  writeVerifiedOnHardware: false,
);

ModbusGuard _writeGuard() => const ModbusGuard(
  allowedFunctions: {ModbusFunction.writeMultipleRegisters},
  readRanges: [],
  writeRanges: [RegisterRange(0, 10)],
  writeVerifiedOnHardware: true,
);

Future<PipelineWriteAuthorization> _authorizeWrite({
  required int address,
  required List<int> values,
}) async {
  final now = DateTime.now().toUtc();
  final controller = AuthorizationController(
    authenticator: const MockTechnicianAuthenticator(demoPin: 'test-pin'),
    clock: () => now,
  );
  await controller.unlock(
    tier: AuthorizationTier.technician,
    credentials: 'test-pin',
  );
  const context = DeviceWriteContext(
    deviceId: 'test-device',
    sessionId: 'test-session',
    profileModel: 'test-model',
    profileFirmware: 'test-firmware',
    connectedModel: 'test-model',
    connectedFirmware: 'test-firmware',
    linkHealthy: true,
    writeLocked: false,
    state: DeviceWriteState.known,
  );
  const planHash = 'the-shown-plan';
  final confirmation = mintShownPlanConfirmation(
    shownPlanHash: planHash,
    deviceId: context.deviceId,
    sessionId: context.sessionId,
    expiresAt: now.add(const Duration(minutes: 5)),
  );
  final pipeline = VerifiedWritePipeline(
    transport: ParameterTransport.physical(
      read: (_) async => 0,
      readAll: () async => const {},
      write: (_, _, _) async {},
    ),
    audit: AuditChain(secretStore: InMemorySecretStore()),
    clock: () => now,
  );
  return pipeline.authorizeModbusWrite(
    functionCode: ModbusFunction.writeMultipleRegisters.code,
    address: address,
    values: values,
    authorizationController: controller,
    context: context,
    confirmation: confirmation,
    shownPlanHash: planHash,
    safetyAcknowledged: true,
  );
}

Stream<List<int>> _tcpInverterResponse(
  List<int> request,
  SimulatedInverterAdapter adapter,
) async* {
  final decodedRequest = const ModbusTcpCodec().decode(request);
  final rtuRequest = const ModbusRtuCodec().encode(
    ModbusRtuFrame(
      address: decodedRequest.unitId,
      functionCode: decodedRequest.functionCode,
      data: decodedRequest.data,
    ),
  );
  final rtuResponse = adapter.respondRtu(rtuRequest);
  late final int functionCode;
  late final List<int> data;
  try {
    final decoded = const ModbusRtuCodec().decode(rtuResponse);
    functionCode = decoded.functionCode;
    data = decoded.data;
  } on ModbusExceptionResponse catch (exception) {
    functionCode = exception.functionCode | 0x80;
    data = [exception.exceptionCode];
  }
  final response = const ModbusTcpCodec().encode(
    ModbusTcpFrame(
      transactionId: decodedRequest.transactionId,
      unitId: decodedRequest.unitId,
      functionCode: functionCode,
      data: data,
    ),
  );
  yield response.sublist(0, 4);
  yield response.sublist(4);
}

void main() {
  test('RTU reads simulated inverter registers', () async {
    final adapter = SimulatedInverterAdapter();
    final bytes = _RecordingByteTransport(
      (request) {
        final response = adapter.respondRtu(request);
        return Stream.fromIterable([
          response.sublist(0, 2),
          response.sublist(2),
        ]);
      },
    );
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: RtuLink(transport: bytes, baudRate: 115200),
    );

    expect(await client.readRegisters(0, 2, unitId: 1), [540, 102]);
  });

  test('loopback link delegates RTU frames to the simulated inverter', () async {
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: LoopbackLink(SimulatedInverterAdapter()),
    );

    expect(await client.readRegisters(0, 1, unitId: 1), [540]);
  });

  test('TCP reads simulated inverter registers across partial reads', () async {
    final adapter = SimulatedInverterAdapter();
    final bytes = _RecordingByteTransport(
      (request) => _tcpInverterResponse(request, adapter),
    );
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: TcpLink(transport: bytes),
    );

    expect(await client.readRegisters(0, 2, unitId: 1), [540, 102]);
  });

  test('input-register guard selects function code 0x04', () async {
    final link = _RecordingLink(
      (_) async => [1, 0x04, 2, 0, 7],
    );
    final client = ModbusClient(
      guard: _readGuard(function: ModbusFunction.readInputRegisters),
      timeout: const Duration(seconds: 1),
      link: link,
    );

    expect(await client.readRegisters(0, 1, unitId: 1), [7]);
    expect(link.requests.single[1], ModbusFunction.readInputRegisters.code);
  });

  test('guard-blocked requests never reach the link', () async {
    final link = _RecordingLink((_) async => const []);
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: link,
    );

    await expectLater(
      client.readRegisters(20, 1, unitId: 1),
      throwsA(isA<ModbusGuardException>()),
    );
    expect(link.requests, isEmpty);
  });

  test('write without pipeline authorization is rejected before I/O', () async {
    final link = _RecordingLink((_) async => const []);
    final client = ModbusClient(
      guard: _writeGuard(),
      timeout: const Duration(seconds: 1),
      link: link,
    );

    await expectLater(
      client.writeRegisters(
        0,
        [42],
        unitId: 1,
        authorization: null,
      ),
      throwsA(isA<ModbusGuardException>()),
    );
    expect(link.requests, isEmpty);
  });

  test('pipeline authorization is single-use', () async {
    final link = _RecordingLink(
      (request) async => [
        request[0],
        request[1],
        request[2],
        request[3],
        request[4],
        request[5],
      ],
    );
    final client = ModbusClient(
      guard: _writeGuard(),
      timeout: const Duration(seconds: 1),
      link: link,
    );
    final authorization = await _authorizeWrite(address: 0, values: [42]);

    await client.writeRegisters(
      0,
      [42],
      unitId: 1,
      authorization: authorization,
    );
    await expectLater(
      client.writeRegisters(
        0,
        [42],
        unitId: 1,
        authorization: authorization,
      ),
      throwsA(isA<ModbusGuardException>()),
    );
    expect(link.requests, hasLength(1));
  });

  test('pipeline authorization is bound to function and write values', () async {
    final link = _RecordingLink(
      (request) async => [
        request[0],
        request[1],
        request[2],
        request[3],
        request[4],
        request[5],
      ],
    );
    final client = ModbusClient(
      guard: _writeGuard(),
      timeout: const Duration(seconds: 1),
      link: link,
    );
    final authorization = await _authorizeWrite(address: 0, values: [42]);
    final now = DateTime.now().toUtc();

    expect(
      authorization.consume(
        functionCode: 0x06,
        address: 0,
        values: [42],
        now: now,
      ),
      isFalse,
    );
    expect(
      authorization.consume(
        functionCode: 0x10,
        address: 1,
        values: [42],
        now: now,
      ),
      isFalse,
    );
    expect(
      authorization.consume(
        functionCode: 0x10,
        address: 0,
        values: [43],
        now: now,
      ),
      isFalse,
    );
    expect(
      authorization.consume(
        functionCode: 0x10,
        address: 0,
        values: [42, 43],
        now: now,
      ),
      isFalse,
    );

    await client.writeRegisters(
      0,
      [42],
      unitId: 1,
      authorization: authorization,
    );
    expect(link.requests, hasLength(1));
  });

  test('link timeout becomes ModbusTimeout', () async {
    final link = _RecordingLink(
      (_) => Completer<List<int>>().future,
    );
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(milliseconds: 5),
      link: link,
    );

    await expectLater(
      client.readRegisters(0, 1, unitId: 1),
      throwsA(isA<ModbusTimeout>()),
    );
  });

  test('exception responses preserve their Modbus exception', () async {
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: _RecordingLink((_) async => [1, 0x83, 2]),
    );

    await expectLater(
      client.readRegisters(0, 1, unitId: 1),
      throwsA(isA<ModbusExceptionResponse>()),
    );
  });

  test('read byte-count mismatch is rejected', () async {
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: _RecordingLink((_) async => [1, 0x03, 2, 0, 1]),
    );

    await expectLater(
      client.readRegisters(0, 2, unitId: 1),
      throwsFormatException,
    );
  });

  test('PDU larger than 253 bytes is rejected', () {
    expect(
      () => const ModbusTcpCodec().encode(
        ModbusTcpFrame(
          transactionId: 1,
          unitId: 1,
          functionCode: 0x03,
          data: List.filled(253, 0),
        ),
      ),
      throwsFormatException,
    );
  });

  test('RTU link rejects response address zero', () async {
    final bytes = _RecordingByteTransport((_) {
      final response = [0, 0x03, 2, 0, 7];
      final crc = ModbusCrc16.calculate(response);
      return Stream.value([...response, crc & 0xff, crc >> 8]);
    });
    final client = ModbusClient(
      guard: _readGuard(),
      timeout: const Duration(seconds: 1),
      link: RtuLink(transport: bytes, baudRate: 115200),
    );

    await expectLater(
      client.readRegisters(0, 1, unitId: 1),
      throwsFormatException,
    );
  });
}
