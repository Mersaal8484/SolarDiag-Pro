import 'dart:convert';

class ResearchReference {
  const ResearchReference({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.retrievedOn,
    required this.exactVersion,
    required this.license,
    required this.obligations,
    required this.scope,
    required this.usedFor,
    required this.derivedArtifacts,
    required this.profileDocumentIds,
    required this.verificationStatus,
    required this.legalReview,
    required this.noticeRequired,
    required this.ndaRestricted,
  });

  final String id;
  final String title;
  final String type;
  final Uri url;
  final DateTime retrievedOn;
  final String exactVersion;
  final String license;
  final List<String> obligations;
  final String scope;
  final List<String> usedFor;
  final List<String> derivedArtifacts;
  final List<String> profileDocumentIds;
  final String verificationStatus;
  final bool legalReview;
  final bool noticeRequired;
  final bool ndaRestricted;
}

class ReferenceRegistry {
  ReferenceRegistry._(this.references);
  final Map<String, ResearchReference> references;

  static ReferenceRegistry fromJson(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, Object?>) {
      throw const FormatException('Reference registry root must be an object.');
    }
    final rawReferences = root['references'];
    if (rawReferences is! List) {
      throw const FormatException('references must be an array.');
    }
    final result = <String, ResearchReference>{};
    for (var index = 0; index < rawReferences.length; index++) {
      final raw = rawReferences[index];
      if (raw is! Map<String, Object?>) {
        throw FormatException('references[$index] must be an object.');
      }
      final path = 'references[$index]';
      final urlText = _requiredString(raw, 'url', path);
      final url = Uri.tryParse(urlText);
      if (url == null || !url.hasScheme) {
        throw FormatException('$path.url must be an absolute URI.');
      }
      final retrievedText = _requiredString(raw, 'retrieved_on', path);
      final retrievedOn = DateTime.tryParse(retrievedText);
      if (retrievedOn == null) {
        throw FormatException('$path.retrieved_on must be an ISO date.');
      }
      final reference = ResearchReference(
        id: _requiredString(raw, 'id', path),
        title: _requiredString(raw, 'title', path),
        type: _requiredString(raw, 'type', path),
        url: url,
        retrievedOn: retrievedOn,
        exactVersion: _requiredString(raw, 'exact_version', path),
        license: _requiredString(raw, 'license', path),
        obligations: _stringList(raw, 'obligations', path),
        scope: _requiredString(raw, 'scope', path),
        usedFor: _stringList(raw, 'used_for', path),
        derivedArtifacts: _stringList(raw, 'derived_artifacts', path),
        profileDocumentIds: _stringList(raw, 'profile_document_ids', path),
        verificationStatus: _requiredString(raw, 'verification_status', path),
        legalReview: _requiredBool(raw, 'legal_review', path),
        noticeRequired: _requiredBool(raw, 'notice_required', path),
        ndaRestricted: _requiredBool(raw, 'nda_restricted', path),
      );
      if (result.containsKey(reference.id)) {
        throw FormatException('Duplicate reference: ${reference.id}');
      }
      result[reference.id] = reference;
    }
    return ReferenceRegistry._(Map.unmodifiable(result));
  }

  void validateExport(Iterable<String> ids) {
    for (final id in ids) {
      final reference = references[id];
      if (reference == null) {
        throw FormatException('Unknown reference: $id');
      }
      if (reference.ndaRestricted) {
        throw FormatException(
          'NDA-restricted reference cannot be exported: $id',
        );
      }
    }
  }

  void validateReuseCompliance() {
    final notices = thirdPartyNotices();
    for (final reference in references.values.where(
      (item) => item.type == 'open-source-research',
    )) {
      if (!reference.noticeRequired) {
        throw FormatException(
          '${reference.id} reuses external code/research without a required notice.',
        );
      }
      if (reference.license.startsWith('LicenseRef-')) {
        throw FormatException(
          '${reference.id} reused-code entry requires an SPDX license.',
        );
      }
      if (!reference.legalReview) {
        throw FormatException(
          '${reference.id} reused-code entry requires recorded legal review.',
        );
      }
      if (!notices.contains('`${reference.id}`') ||
          !notices.contains('- License: ${reference.license}') ||
          !notices.contains(reference.obligations.first)) {
        throw FormatException(
          '${reference.id} is absent or incomplete in THIRD_PARTY_NOTICES.',
        );
      }
    }
  }

  String thirdPartyNotices() {
    final external = references.values.where(
      (reference) => reference.type != 'internal',
    );
    final buffer = StringBuffer(
      '# Third-party notices\n\nGenerated from `docs/research/references.json`.\n',
    );
    for (final reference in external) {
      buffer
        ..writeln('\n## ${reference.title}')
        ..writeln('\n- Reference: `${reference.id}`')
        ..writeln('- Source: ${reference.url}')
        ..writeln('- Version/commit: ${reference.exactVersion}')
        ..writeln('- License: ${reference.license}')
        ..writeln('- Notice required: ${reference.noticeRequired}')
        ..writeln('- Legal review: ${reference.legalReview}')
        ..writeln('- Obligations: ${reference.obligations.join('; ')}');
    }
    return buffer.toString();
  }

  static String _requiredString(
    Map<String, Object?> map,
    String key,
    String path,
  ) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$path.$key must be a non-empty string.');
    }
    return value.trim();
  }

  static bool _requiredBool(Map<String, Object?> map, String key, String path) {
    final value = map[key];
    if (value is! bool) {
      throw FormatException('$path.$key must be a boolean.');
    }
    return value;
  }

  static List<String> _stringList(
    Map<String, Object?> map,
    String key,
    String path,
  ) {
    final value = map[key];
    if (value is! List ||
        value.isEmpty ||
        value.any((item) => item is! String || item.trim().isEmpty)) {
      throw FormatException('$path.$key must be a non-empty string array.');
    }
    return List<String>.unmodifiable(value.whereType<String>());
  }
}
