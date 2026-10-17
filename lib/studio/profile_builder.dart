import 'dart:convert';

enum FieldDataType {
  unsigned8,
  unsigned16,
  signed16,
  unsigned32,
  ascii,
  bitfield,
}

class FieldMapping {
  const FieldMapping({
    required this.field,
    required this.frameIdentifier,
    required this.offset,
    required this.length,
    required this.dataType,
    required this.scale,
    required this.unit,
    required this.evidenceReferences,
  });
  final String field;
  final int frameIdentifier;
  final int offset;
  final int length;
  final FieldDataType dataType;
  final double scale;
  final String unit;
  final List<String> evidenceReferences;
}

class StudioProfileDraft {
  const StudioProfileDraft({
    required this.id,
    required this.manufacturer,
    required this.family,
    required this.mappings,
    required this.referenceIds,
  });
  final String id;
  final String manufacturer;
  final String family;
  final List<FieldMapping> mappings;
  final List<String> referenceIds;
}

class DraftValidationIssue {
  const DraftValidationIssue(this.code, this.message);
  final String code;
  final String message;
}

class DraftValidationResult {
  const DraftValidationResult(this.issues);
  final List<DraftValidationIssue> issues;
  bool get isValid => issues.isEmpty;
}

class ProfileBuilder {
  const ProfileBuilder();
  DraftValidationResult validate(StudioProfileDraft draft) {
    final issues = <DraftValidationIssue>[];
    if (draft.id.trim().isEmpty) {
      issues.add(
        const DraftValidationIssue('missing_id', 'Draft id is required.'),
      );
    }
    if (draft.manufacturer.trim().isEmpty || draft.family.trim().isEmpty) {
      issues.add(
        const DraftValidationIssue(
          'missing_identity',
          'Manufacturer and family are required.',
        ),
      );
    }
    if (draft.mappings.isEmpty) {
      issues.add(
        const DraftValidationIssue(
          'missing_mappings',
          'At least one evidenced mapping is required.',
        ),
      );
    }
    final fields = <String>{};
    for (final mapping in draft.mappings) {
      if (!fields.add(mapping.field)) {
        issues.add(
          DraftValidationIssue(
            'duplicate_field',
            'Duplicate mapping: ${mapping.field}',
          ),
        );
      }
      if (mapping.offset < 0 ||
          mapping.length <= 0 ||
          mapping.offset + mapping.length > 8) {
        issues.add(
          DraftValidationIssue(
            'invalid_bounds',
            'Mapping ${mapping.field} exceeds a classic CAN payload.',
          ),
        );
      }
      if (mapping.evidenceReferences.isEmpty) {
        issues.add(
          DraftValidationIssue(
            'missing_evidence',
            'Mapping ${mapping.field} has no evidence.',
          ),
        );
      }
    }
    return DraftValidationResult(List.unmodifiable(issues));
  }

  String exportStudioDraft(StudioProfileDraft draft) {
    final validation = validate(draft);
    if (!validation.isValid) {
      throw StateError('Invalid drafts cannot be exported.');
    }
    return const JsonEncoder.withIndent('  ').convert({
      'schema_version': 1,
      'id': draft.id,
      'manufacturer': draft.manufacturer,
      'family': draft.family,
      'verification_status': 'studio-draft',
      'loadable_in_technician_mode': false,
      'write_capability': 'disabled',
      'reference_ids': draft.referenceIds,
      'telemetry_mappings': [
        for (final mapping in draft.mappings)
          {
            'field': mapping.field,
            'frame_identifier': mapping.frameIdentifier,
            'offset': mapping.offset,
            'length': mapping.length,
            'data_type': mapping.dataType.name,
            'scale': mapping.scale,
            'unit': mapping.unit,
            'evidence': mapping.evidenceReferences,
          },
      ],
    });
  }
}
