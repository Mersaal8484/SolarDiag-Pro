class ProtocolHypothesis {
  const ProtocolHypothesis({
    required this.id,
    required this.claim,
    required this.evidenceReferences,
    required this.confidence,
    this.fieldIdentifier,
    this.byteOffset,
    this.bitIndex,
  });

  final String id;
  final String claim;
  final List<String> evidenceReferences;
  final double confidence;
  final int? fieldIdentifier;
  final int? byteOffset;
  final int? bitIndex;

  Map<String, Object?> toJson() => {
    'id': id,
    'claim': claim,
    'evidence_references': evidenceReferences,
    'confidence': confidence,
    'field_identifier': fieldIdentifier,
    'byte_offset': byteOffset,
    'bit_index': bitIndex,
    'transmittable': false,
  };
}
