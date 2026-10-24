// T2 — Correctness (C1–C6)
// Tests are written to FAIL against the un-fixed code; after fixes are applied
// each group must pass. See docs/reports/T2_CORRECTNESS.md for defect IDs.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/auth/authorization_controller.dart';
import 'package:solardiag_pro/auth/confirmation_factory.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';
import 'package:solardiag_pro/protocols/modbus/rtu_codec.dart';
import 'package:solardiag_pro/protocols/modbus/crc16.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_models.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_client.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_guard.dart';
import 'package:solardiag_pro/protocols/modbus/modbus_link.dart';
import 'package:solardiag_pro/integration/compatibility_engine.dart';
import 'package:solardiag_pro/integration/compatibility_models.dart';
import 'package:solardiag_pro/session/device_session.dart';

class _CheckOnlyLink implements ModbusLink {
  @override
  Future<List<int>> exchange(
    List<int> request, {
    required Duration timeout,
  }) async => const [];
}

Future<PipelineWriteAuthorization> _mintModbusAuthorization({
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
  final context = DeviceWriteContext(
    deviceId: 'device',
    sessionId: 'session',
    profileModel: 'model',
    profileFirmware: 'firmware',
    connectedModel: 'model',
    connectedFirmware: 'firmware',
    linkHealthy: true,
    writeLocked: false,
    state: DeviceWriteState.known,
  );
  const planHash = 'shown-plan-hash';
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

// ── helpers ──────────────────────────────────────────────────────────────────

List<int> _buildFrame(int address, int functionCode, List<int> data) {
  final bytes = [address, functionCode, ...data];
  final crc = ModbusCrc16.calculate(bytes);
  return [...bytes, crc & 0xff, crc >> 8];
}

List<int> _buildExceptionFrame(int functionCode, int exceptionCode) {
  final bytes = [0x01, functionCode | 0x80, exceptionCode];
  final crc = ModbusCrc16.calculate(bytes);
  return [...bytes, crc & 0xff, crc >> 8];
}

// ── C1: ModbusRtuStreamDecoder — exception-response handling ─────────────────

void main() {
  group('C1 – ModbusRtuStreamDecoder', () {
    // C1-a: an exception frame must NOT crash the decoder.
    //       Before fix: rethrow causes exception to propagate from add().
    //       After fix:  add() returns List<ModbusFrameResult>; exception frames
    //                   appear as ExceptionFrameResult.
    test('C1-a exception frame returned as result, not thrown', () {
      final decoder = ModbusRtuStreamDecoder();
      final exFrame = _buildExceptionFrame(0x03, 0x02); // FC3, exception code 2

      late List<ModbusFrameResult> results;
      expect(
        () {
          results = decoder.add(exFrame);
        },
        returnsNormally,
        reason: 'C1: add() must not rethrow ModbusExceptionResponse',
      );

      expect(results, hasLength(1));
      expect(results.first.isException, isTrue);
      expect(
        (results.first as ExceptionFrameResult).exception.exceptionCode,
        2,
      );
    });

    // C1-b: a normal frame returns a SuccessFrameResult
    test('C1-b normal frame returned as SuccessFrameResult', () {
      final decoder = ModbusRtuStreamDecoder();
      // FC3 response: byteCount=2, value=0x0001
      final frame = _buildFrame(0x01, 0x03, [0x02, 0x00, 0x01]);
      final results = decoder.add(frame);
      expect(results, hasLength(1));
      expect(results.first.isException, isFalse);
      expect((results.first as SuccessFrameResult).frame.functionCode, 0x03);
    });

    // C1-c: two valid frames in one add() call are both decoded
    test('C1-c two consecutive frames decoded from one call', () {
      final decoder = ModbusRtuStreamDecoder();
      final f1 = _buildFrame(0x01, 0x03, [0x02, 0x00, 0x0A]);
      final f2 = _buildFrame(0x02, 0x03, [0x02, 0x00, 0x0B]);
      final results = decoder.add([...f1, ...f2]);
      expect(results, hasLength(2));
    });

    // C1-d: garbage bytes before a valid frame are skipped (no crash)
    test('C1-d garbage bytes before valid frame are skipped', () {
      final decoder = ModbusRtuStreamDecoder();
      final validFrame = _buildFrame(0x01, 0x03, [0x02, 0x00, 0x05]);
      final garbage = [0xDE, 0xAD, 0xBE, 0xEF];
      expect(() {
        decoder.add([...garbage, ...validFrame]);
      }, returnsNormally);
    });

    // C1-e: exception frame followed by normal frame — both decoded
    test('C1-e exception frame followed by normal frame — both decoded', () {
      final decoder = ModbusRtuStreamDecoder();
      final ex = _buildExceptionFrame(0x10, 0x03);
      final ok = _buildFrame(0x01, 0x03, [0x02, 0x00, 0x07]);
      final results = decoder.add([...ex, ...ok]);
      expect(results, hasLength(2));
      expect(results.first.isException, isTrue);
      expect(results.last.isException, isFalse);
    });
  });

  // ── C2: ModbusClient ────────────────────────────────────────────────────────

  group('C2 – ModbusClient', () {
    ModbusGuard readOnlyGuard() => const ModbusGuard(
      allowedFunctions: {ModbusFunction.readHoldingRegisters},
      readRanges: [RegisterRange(0, 100)],
      writeRanges: [],
      writeVerifiedOnHardware: false,
    );

    ModbusGuard writeGuard() => const ModbusGuard(
      allowedFunctions: {
        ModbusFunction.readHoldingRegisters,
        ModbusFunction.writeMultipleRegisters,
      },
      readRanges: [RegisterRange(0, 100)],
      writeRanges: [RegisterRange(0, 100)],
      writeVerifiedOnHardware: true,
    );

    // C2-a: ModbusClient can be constructed (class exists and takes guard)
    test('C2-a ModbusClient constructs with guard and timeout', () {
      final client = ModbusClient(
        guard: readOnlyGuard(),
        timeout: const Duration(seconds: 1),
        link: _CheckOnlyLink(),
      );
      expect(client, isNotNull);
    });

    // C2-b: read within allowed range does not throw a guard exception
    test(
      'C2-b readRegisters within allowed range does not throw guard error',
      () {
        final client = ModbusClient(
          guard: readOnlyGuard(),
          timeout: const Duration(seconds: 1),
          link: _CheckOnlyLink(),
        );
        // Guard check is synchronous; call returns normally (future may fail on
        // transport, but the guard must not reject an in-range read).
        expect(
          () => client.checkRead(address: 0, count: 10, unitId: 1),
          returnsNormally,
        );
      },
    );

    // C2-c: read outside allowed range throws ModbusGuardException
    test(
      'C2-c readRegisters outside allowed range throws ModbusGuardException',
      () {
        final client = ModbusClient(
          guard: readOnlyGuard(),
          timeout: const Duration(seconds: 1),
          link: _CheckOnlyLink(),
        );
        expect(
          () => client.checkRead(address: 200, count: 5, unitId: 1),
          throwsA(isA<ModbusGuardException>()),
        );
      },
    );

    // C2-d: write blocked without pipeline authorization
    test('C2-d write blocked without pipeline authorization', () {
      final client = ModbusClient(
        guard: writeGuard(),
        timeout: const Duration(seconds: 1),
        link: _CheckOnlyLink(),
      );
      expect(
        () => client.checkWrite(
          address: 0,
          values: [1, 2],
          unitId: 1,
          authorization: null,
        ),
        throwsA(isA<ModbusGuardException>()),
      );
    });

    // C2-e: write blocked when writeVerifiedOnHardware == false
    test('C2-e write blocked when hardware not verified by guard', () {
      final client = ModbusClient(
        guard: readOnlyGuard(), // writeVerifiedOnHardware: false
        timeout: const Duration(seconds: 1),
        link: _CheckOnlyLink(),
      );
      expect(
        () => client.checkWrite(
          address: 0,
          values: [1],
          unitId: 1,
          authorization: null,
        ),
        throwsA(isA<ModbusGuardException>()),
      );
    });

    // C2-f: write succeeds (guard-check passes) when all gates open
    test(
      'C2-f checkWrite passes with a valid pipeline authorization',
      () async {
        final client = ModbusClient(
          guard: writeGuard(),
          timeout: const Duration(seconds: 1),
          link: _CheckOnlyLink(),
        );
        final authorization = await _mintModbusAuthorization(
          address: 0,
          values: [1],
        );
        expect(
          () => client.checkWrite(
            address: 0,
            values: [1],
            unitId: 1,
            authorization: authorization,
          ),
          returnsNormally,
        );
      },
    );
  });

  // ── C4: CompatibilityEngine evidence quality weighting ──────────────────────

  group('C4 – CompatibilityEngine evidence quality', () {
    // C4-a: communitySourced evidence downgrades compatible → attention
    test(
      'C4-a communitySourced voltage window gives attention, not compatible',
      () {
        const battery = BatteryIntegrationProfile(
          chargeVoltageWindow: SourcedValue.reported(
            VoltageWindow(minimum: 54.0, maximum: 58.4),
            EvidenceSource.communitySourced,
          ),
          dischargeVoltageWindow: SourcedValue.unavailable('not_reported'),
          maximumChargeCurrent: SourcedValue.unavailable('not_reported'),
          maximumDischargeCurrent: SourcedValue.unavailable('not_reported'),
          chemistry: SourcedValue.unavailable('not_reported'),
          spokenProtocols: {},
        );
        const inverter = InverterIntegrationProfile(
          configuredChargeVoltage: SourcedValue.reported(
            56.0,
            EvidenceSource.deviceReported,
          ),
          configuredLowVoltageCutoff: SourcedValue.unavailable('not_reported'),
          configuredChargeCurrent: SourcedValue.unavailable('not_reported'),
          configuredDischargeCurrent: SourcedValue.unavailable('not_reported'),
          supportedChemistries: {},
          supportedBatteryProtocols: {},
        );
        final assessment = const CompatibilityEngine().assess(
          battery: battery,
          inverter: inverter,
        );
        final chargeVoltageFinding = assessment.findings.firstWhere(
          (f) => f.code == 'CHARGE_VOLTAGE',
        );
        // communitySourced → must NOT be 'compatible', must be 'attention'
        expect(
          chargeVoltageFinding.state,
          CompatibilityState.attention,
          reason:
              'C4: communitySourced evidence must downgrade compatible→attention',
        );
        expect(
          chargeVoltageFinding.evidenceQuality,
          EvidenceQuality.communitySourced,
        );
      },
    );

    // C4-b: verifiedProfile source yields compatible when values fit
    test('C4-b verifiedProfile source yields compatible when values fit', () {
      const battery = BatteryIntegrationProfile(
        chargeVoltageWindow: SourcedValue.reported(
          VoltageWindow(minimum: 54.0, maximum: 58.4),
          EvidenceSource.verifiedProfile,
        ),
        dischargeVoltageWindow: SourcedValue.unavailable('not_reported'),
        maximumChargeCurrent: SourcedValue.unavailable('not_reported'),
        maximumDischargeCurrent: SourcedValue.unavailable('not_reported'),
        chemistry: SourcedValue.unavailable('not_reported'),
        spokenProtocols: {},
      );
      const inverter = InverterIntegrationProfile(
        configuredChargeVoltage: SourcedValue.reported(
          56.0,
          EvidenceSource.verifiedProfile,
        ),
        configuredLowVoltageCutoff: SourcedValue.unavailable('not_reported'),
        configuredChargeCurrent: SourcedValue.unavailable('not_reported'),
        configuredDischargeCurrent: SourcedValue.unavailable('not_reported'),
        supportedChemistries: {},
        supportedBatteryProtocols: {},
      );
      final assessment = const CompatibilityEngine().assess(
        battery: battery,
        inverter: inverter,
      );
      final chargeVoltageFinding = assessment.findings.firstWhere(
        (f) => f.code == 'CHARGE_VOLTAGE',
      );
      expect(chargeVoltageFinding.state, CompatibilityState.compatible);
      expect(chargeVoltageFinding.evidenceQuality, EvidenceQuality.verified);
    });

    // C4-c: deviceReported source for current limit also checked
    test(
      'C4-c deviceReported source with compatible current yields compatible',
      () {
        const battery = BatteryIntegrationProfile(
          chargeVoltageWindow: SourcedValue.unavailable('not_reported'),
          dischargeVoltageWindow: SourcedValue.unavailable('not_reported'),
          maximumChargeCurrent: SourcedValue.reported(
            100.0,
            EvidenceSource.deviceReported,
          ),
          maximumDischargeCurrent: SourcedValue.unavailable('not_reported'),
          chemistry: SourcedValue.unavailable('not_reported'),
          spokenProtocols: {},
        );
        const inverter = InverterIntegrationProfile(
          configuredChargeVoltage: SourcedValue.unavailable('not_reported'),
          configuredLowVoltageCutoff: SourcedValue.unavailable('not_reported'),
          configuredChargeCurrent: SourcedValue.reported(
            80.0,
            EvidenceSource.deviceReported,
          ),
          configuredDischargeCurrent: SourcedValue.unavailable('not_reported'),
          supportedChemistries: {},
          supportedBatteryProtocols: {},
        );
        final assessment = const CompatibilityEngine().assess(
          battery: battery,
          inverter: inverter,
        );
        final finding = assessment.findings.firstWhere(
          (f) => f.code == 'CHARGE_CURRENT',
        );
        // deviceReported is treated same as verifiedProfile for state (C4 only
        // applies the downgrade to communitySourced)
        expect(finding.state, CompatibilityState.compatible);
      },
    );

    test('C4-d userProvided evidence caps compatible result at attention', () {
      const battery = BatteryIntegrationProfile(
        chargeVoltageWindow: SourcedValue.reported(
          VoltageWindow(minimum: 54, maximum: 58.4),
          EvidenceSource.verifiedProfile,
        ),
        dischargeVoltageWindow: SourcedValue.unavailable('not_reported'),
        maximumChargeCurrent: SourcedValue.unavailable('not_reported'),
        maximumDischargeCurrent: SourcedValue.unavailable('not_reported'),
        chemistry: SourcedValue.unavailable('not_reported'),
        spokenProtocols: {},
      );
      const inverter = InverterIntegrationProfile(
        configuredChargeVoltage: SourcedValue.reported(
          56,
          EvidenceSource.userProvided,
        ),
        configuredLowVoltageCutoff: SourcedValue.unavailable('not_reported'),
        configuredChargeCurrent: SourcedValue.unavailable('not_reported'),
        configuredDischargeCurrent: SourcedValue.unavailable('not_reported'),
        supportedChemistries: {},
        supportedBatteryProtocols: {},
      );

      final finding = const CompatibilityEngine()
          .assess(battery: battery, inverter: inverter)
          .findings
          .firstWhere((item) => item.code == 'CHARGE_VOLTAGE');

      expect(finding.state, CompatibilityState.attention);
      expect(finding.evidenceQuality, EvidenceQuality.userProvided);
    });

    test('C4-e value within five percent of current limit needs attention', () {
      const battery = BatteryIntegrationProfile(
        chargeVoltageWindow: SourcedValue.unavailable('not_reported'),
        dischargeVoltageWindow: SourcedValue.unavailable('not_reported'),
        maximumChargeCurrent: SourcedValue.reported(
          100,
          EvidenceSource.verifiedProfile,
        ),
        maximumDischargeCurrent: SourcedValue.unavailable('not_reported'),
        chemistry: SourcedValue.unavailable('not_reported'),
        spokenProtocols: {},
      );
      const inverter = InverterIntegrationProfile(
        configuredChargeVoltage: SourcedValue.unavailable('not_reported'),
        configuredLowVoltageCutoff: SourcedValue.unavailable('not_reported'),
        configuredChargeCurrent: SourcedValue.reported(
          96,
          EvidenceSource.deviceReported,
        ),
        configuredDischargeCurrent: SourcedValue.unavailable('not_reported'),
        supportedChemistries: {},
        supportedBatteryProtocols: {},
      );

      final finding = const CompatibilityEngine()
          .assess(battery: battery, inverter: inverter)
          .findings
          .firstWhere((item) => item.code == 'CHARGE_CURRENT');

      expect(finding.state, CompatibilityState.attention);
      expect(finding.evidence['near_limit'], isTrue);
    });
  });

  // ── C5: linkDiagnostics zero-default ─────────────────────────────────────────

  group('C5 – linkDiagnostics defaults', () {
    // C5-a: when _linkHealth is null, timeouts must default to 0, not 1.
    //       Defaulting to 1 invents a fake timeout (truthfulness defect).
    test('C5-a timeouts default to 0 when linkHealth is null', () {
      final session = DeviceSession(autoStart: false);
      addTearDown(session.dispose);
      // linkHealth is null before any poll
      final result = session.linkDiagnostics;
      // If LINK_ERRORS finding is present, its timeouts evidence must be 0
      final linkErrorFinding = result.findings.where(
        (f) => f.code == 'LINK_ERRORS',
      );
      for (final f in linkErrorFinding) {
        expect(
          f.evidence['timeouts'],
          equals(0),
          reason:
              'C5: invented timeout=1 when linkHealth==null is a truthfulness defect',
        );
      }
    });
  });

  // ── C6: simulated inverter profile file ─────────────────────────────────────

  group('C6 – device profiles', () {
    // C6-a: simulated inverter profile JSON must exist so the inverter
    //       simulator path is exercised without real hardware.
    test(
      'C6-a simulated inverter profile JSON exists and is valid schema v2',
      () {
        final dir = Directory('device_profiles/inverters/_simulated');
        expect(
          dir.existsSync(),
          isTrue,
          reason: 'C6: device_profiles/inverters/_simulated/ must exist',
        );
        final files = dir.listSync().whereType<File>().toList();
        expect(
          files.isNotEmpty,
          isTrue,
          reason: 'C6: at least one simulated inverter JSON must be present',
        );
        final json = jsonDecode(files.first.readAsStringSync()) as Map;
        expect(json['schema_version'], equals(2));
        expect(json['id'], equals('solardiag.simulated.inverter.v1'));
        expect(json['category'], equals('inverter'));
        expect(json['simulated'], isTrue);
      },
    );
  });
}
