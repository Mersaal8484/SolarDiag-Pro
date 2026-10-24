import '../protocols/modbus/crc16.dart';
import 'capture_models.dart';
import 'profile_builder.dart';

enum ValidationCheckState { passed, failed, notApplicable }

class OfflineValidationCheck {
  const OfflineValidationCheck({
    required this.code,
    required this.state,
    required this.detail,
  });
  final String code;
  final ValidationCheckState state;
  final String detail;
}

class OfflineValidationResult {
  const OfflineValidationResult({
    required this.checks,
    required this.decodedValues,
    required this.generatedParserTests,
  });
  final List<OfflineValidationCheck> checks;
  final Map<String, List<num>> decodedValues;
  final List<String> generatedParserTests;
  bool get passed =>
      checks.every((check) => check.state != ValidationCheckState.failed);
}

class OfflineValidationRequest {
  const OfflineValidationRequest({
    required this.draft,
    required this.session,
    this.mockResponses = const {},
    this.expectedIdentity,
    this.observedIdentity,
  });
  final StudioProfileDraft draft;
  final CaptureSession session;
  final Map<int, List<int>> mockResponses;
  final String? expectedIdentity;
  final String? observedIdentity;
}

class StudioReleaseGateRequest {
  const StudioReleaseGateRequest({
    required this.validation,
    required this.legalReviewCompleted,
    required this.containsNdaMaterial,
    required this.physicalHardwareValidated,
  });

  final OfflineValidationResult validation;
  final bool legalReviewCompleted;
  final bool containsNdaMaterial;
  final bool physicalHardwareValidated;
}

class StudioReleaseGateResult {
  const StudioReleaseGateResult({required this.blockers});

  final List<String> blockers;
  bool get canRequestPublication => blockers.isEmpty;
  String get checklistPath => 'docs/studio/LEGAL_REVIEW_CHECKLIST.md';
}

class StudioReleaseGate {
  const StudioReleaseGate();

  StudioReleaseGateResult evaluate(StudioReleaseGateRequest request) {
    final blockers = <String>[];
    if (!request.validation.passed) {
      blockers.add('offline_validation_failed');
    }
    if (!request.legalReviewCompleted) {
      blockers.add('legal_review_incomplete');
    }
    if (request.containsNdaMaterial) {
      blockers.add('nda_material_cannot_be_published');
    }
    if (!request.physicalHardwareValidated) {
      blockers.add('physical_hardware_validation_required');
    }
    return StudioReleaseGateResult(blockers: List.unmodifiable(blockers));
  }
}

class StudioValidationRunner {
  const StudioValidationRunner();

  OfflineValidationResult validate(OfflineValidationRequest request) {
    final checks = <OfflineValidationCheck>[];
    final values = <String, List<num>>{};
    final parserTests = <String>[];
    final structural = const ProfileBuilder().validate(request.draft);
    checks.add(
      OfflineValidationCheck(
        code: 'draft_structure',
        state: structural.isValid
            ? ValidationCheckState.passed
            : ValidationCheckState.failed,
        detail: structural.isValid
            ? 'Draft structure and evidence links are valid.'
            : structural.issues.map((issue) => issue.code).join(', '),
      ),
    );

    var decodedFrames = 0;
    for (final mapping in request.draft.mappings) {
      final decoded = <num>[];
      for (final frame in request.session.frames) {
        if (frame.identifier != mapping.frameIdentifier ||
            mapping.offset + mapping.length > frame.rawBytes.length) {
          continue;
        }
        decoded.add(_decode(frame.rawBytes, mapping));
        decodedFrames++;
      }
      values[mapping.field] = List.unmodifiable(decoded);
      parserTests.add(_generatedTest(mapping, decoded.firstOrNull));
    }
    checks.add(
      OfflineValidationCheck(
        code: 'offline_replay',
        state: decodedFrames > 0
            ? ValidationCheckState.passed
            : ValidationCheckState.failed,
        detail: '$decodedFrames mapped field samples decoded offline.',
      ),
    );

    final modbus = request.session.frames
        .where(
          (frame) =>
              frame.protocolHint?.toLowerCase().contains('modbus') ?? false,
        )
        .toList();
    final validCrc = modbus.where((frame) => ModbusCrc16.valid(frame.rawBytes));
    checks.add(
      OfflineValidationCheck(
        code: 'captured_crc',
        state: modbus.isEmpty
            ? ValidationCheckState.notApplicable
            : validCrc.length == modbus.length
            ? ValidationCheckState.passed
            : ValidationCheckState.failed,
        detail: modbus.isEmpty
            ? 'No captured Modbus frames require CRC validation.'
            : '${validCrc.length}/${modbus.length} captured CRC values valid.',
      ),
    );

    var mockFailures = 0;
    for (final entry in request.mockResponses.entries) {
      final relevant = request.draft.mappings.where(
        (mapping) => mapping.frameIdentifier == entry.key,
      );
      for (final mapping in relevant) {
        if (mapping.offset + mapping.length > entry.value.length) {
          mockFailures++;
        } else {
          _decode(entry.value, mapping);
        }
      }
    }
    checks.add(
      OfflineValidationCheck(
        code: 'mock_responses',
        state: mockFailures == 0
            ? ValidationCheckState.passed
            : ValidationCheckState.failed,
        detail: mockFailures == 0
            ? '${request.mockResponses.length} mock responses accepted.'
            : '$mockFailures mock responses violate mapping bounds.',
      ),
    );

    final expected = request.expectedIdentity;
    final observed = request.observedIdentity;
    checks.add(
      OfflineValidationCheck(
        code: 'identity_match',
        state: expected == null || observed == null
            ? ValidationCheckState.notApplicable
            : expected == observed
            ? ValidationCheckState.passed
            : ValidationCheckState.failed,
        detail: expected == null || observed == null
            ? 'Identity evidence not supplied.'
            : expected == observed
            ? 'Observed identity matches the draft target.'
            : 'Observed identity does not match the draft target.',
      ),
    );

    return OfflineValidationResult(
      checks: List.unmodifiable(checks),
      decodedValues: Map.unmodifiable(values),
      generatedParserTests: List.unmodifiable(parserTests),
    );
  }

  num _decode(List<int> bytes, FieldMapping mapping) {
    var raw = 0;
    for (var index = 0; index < mapping.length; index++) {
      raw = (raw << 8) | bytes[mapping.offset + index];
    }
    if (mapping.dataType == FieldDataType.signed16 &&
        mapping.length == 2 &&
        (raw & 0x8000) != 0) {
      raw -= 0x10000;
    }
    return raw * mapping.scale;
  }

  String _generatedTest(FieldMapping mapping, num? expected) =>
      "expect(parse_${mapping.field}(fixture), ${expected ?? 'isNotNull'});";
}
