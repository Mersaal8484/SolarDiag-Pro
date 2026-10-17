import 'dart:convert';

class ResearchReference {
  const ResearchReference({
    required this.id,
    required this.title,
    required this.source,
    required this.license,
    required this.noticeRequired,
    required this.ndaRestricted,
  });
  final String id;
  final String title;
  final String source;
  final String license;
  final bool noticeRequired;
  final bool ndaRestricted;
}

class ReferenceRegistry {
  ReferenceRegistry._(this.references);
  final Map<String, ResearchReference> references;
  static ReferenceRegistry fromJson(String source) {
    final root = jsonDecode(source);
    if (root is! Map<String, Object?> || root['references'] is! List) {
      throw const FormatException('Invalid reference registry.');
    }
    final result = <String, ResearchReference>{};
    for (final raw in root['references']! as List) {
      if (raw is! Map<String, Object?>) {
        throw const FormatException('Reference must be an object.');
      }
      final reference = ResearchReference(
        id: raw['id'] as String,
        title: raw['title'] as String,
        source: raw['source'] as String,
        license: raw['license'] as String,
        noticeRequired: raw['notice_required'] as bool,
        ndaRestricted: raw['nda_restricted'] as bool,
      );
      if (reference.id.isEmpty ||
          reference.source.isEmpty ||
          reference.license.isEmpty) {
        throw const FormatException(
          'Reference id, source, and license are required.',
        );
      }
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
      if (reference == null) throw FormatException('Unknown reference: $id');
      if (reference.ndaRestricted) {
        throw FormatException(
          'NDA-restricted reference cannot be exported: $id',
        );
      }
    }
  }
}
