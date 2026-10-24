import 'dart:convert';
import 'dart:io';

import 'package:solardiag_pro/studio/reference_registry.dart';

void main(List<String> arguments) {
  final registryFile = File('docs/research/references.json');
  if (!registryFile.existsSync()) {
    stderr.writeln('Missing docs/research/references.json');
    exitCode = 1;
    return;
  }

  try {
    final registry = ReferenceRegistry.fromJson(
      registryFile.readAsStringSync(),
    );
    _validateReferences(registry);
    _validateProfileProvenance(registry);
    final notices = registry.thirdPartyNotices();
    final noticesFile = File('THIRD_PARTY_NOTICES.md');
    if (arguments.contains('--check')) {
      if (!noticesFile.existsSync() ||
          noticesFile.readAsStringSync() != notices) {
        throw const FormatException(
          'THIRD_PARTY_NOTICES.md is missing or stale. Run reference_check without --check.',
        );
      }
    } else {
      noticesFile.writeAsStringSync(notices);
    }
    stdout.writeln(
      'Reference registry valid: ${registry.references.length} references.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Reference check failed: ${error.message}');
    exitCode = 1;
  }
}

void _validateReferences(ReferenceRegistry registry) {
  final knownDocumentIds = <String>{};
  for (final reference in registry.references.values) {
    if (!_isSpdxExpression(reference.license)) {
      throw FormatException(
        '${reference.id} has a non-SPDX license identifier: ${reference.license}',
      );
    }
    if (reference.type == 'open-source-research' &&
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(reference.exactVersion)) {
      throw FormatException(
        '${reference.id} must pin a full 40-character Git commit.',
      );
    }
    for (final artifact in reference.derivedArtifacts) {
      if (!File(artifact).existsSync()) {
        throw FormatException(
          '${reference.id} derived artifact does not exist: $artifact',
        );
      }
    }
    for (final documentId in reference.profileDocumentIds) {
      if (!knownDocumentIds.add(documentId.toLowerCase())) {
        throw FormatException('Duplicate profile document id: $documentId');
      }
    }
  }
}

void _validateProfileProvenance(ReferenceRegistry registry) {
  final byDocumentId = <String, ResearchReference>{
    for (final reference in registry.references.values)
      for (final documentId in reference.profileDocumentIds)
        documentId.toLowerCase(): reference,
  };
  final profiles = Directory('device_profiles')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.json') &&
            !file.path.endsWith('profile.schema.json'),
      );
  for (final file in profiles) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw FormatException('${file.path} profile root must be an object.');
    }
    final provenance = decoded['provenance'];
    if (provenance is! Map<String, Object?>) {
      throw FormatException('${file.path} is missing provenance.');
    }
    final documentId = provenance['document_id'];
    if (documentId is! String || documentId.trim().isEmpty) {
      throw FormatException('${file.path} provenance.document_id is required.');
    }
    final reference = byDocumentId[documentId.toLowerCase()];
    if (reference == null) {
      throw FormatException(
        '${file.path} references unknown provenance document: $documentId',
      );
    }
    final normalizedPath = file.path.replaceAll('\\', '/');
    if (!reference.derivedArtifacts.contains(normalizedPath)) {
      throw FormatException(
        '$normalizedPath is not declared by reference ${reference.id}.',
      );
    }
  }
}

bool _isSpdxExpression(String value) =>
    RegExp(r'^(?:LicenseRef-[A-Za-z0-9.-]+|[A-Za-z0-9.-]+)$').hasMatch(value);
