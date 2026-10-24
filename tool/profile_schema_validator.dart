class ProfileSchemaValidator {
  const ProfileSchemaValidator();

  List<String> validate(Object? value, Map<String, Object?> schema) {
    final errors = <String>[];
    _validate(value, schema, r'$', errors);
    return List.unmodifiable(errors);
  }

  void _validate(
    Object? value,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final expectedType = schema['type'];
    if (expectedType is String && !_matchesType(value, expectedType)) {
      errors.add('$path must be $expectedType.');
      return;
    }
    if (schema.containsKey('const') && value != schema['const']) {
      errors.add('$path must equal ${schema['const']}.');
    }
    final allowedValues = schema['enum'];
    if (allowedValues is List && !allowedValues.contains(value)) {
      errors.add('$path must be one of ${allowedValues.join(', ')}.');
    }
    if (value is String) {
      final minimumLength = schema['minLength'];
      if (minimumLength is int && value.length < minimumLength) {
        errors.add('$path must contain at least $minimumLength character(s).');
      }
    }
    if (value is List) {
      final minimumItems = schema['minItems'];
      if (minimumItems is int && value.length < minimumItems) {
        errors.add('$path must contain at least $minimumItems item(s).');
      }
      final itemSchema = schema['items'];
      if (itemSchema is Map<String, Object?>) {
        for (var index = 0; index < value.length; index++) {
          _validate(value[index], itemSchema, '$path[$index]', errors);
        }
      }
    }
    if (value is Map) {
      final required = schema['required'];
      if (required is List) {
        for (final key in required.whereType<String>()) {
          if (!value.containsKey(key)) errors.add('$path.$key is required.');
        }
      }
      final properties = schema['properties'];
      if (properties is Map<String, Object?>) {
        for (final entry in value.entries) {
          final key = entry.key;
          final propertySchema = properties[key];
          if (propertySchema is Map<String, Object?>) {
            _validate(entry.value, propertySchema, '$path.$key', errors);
          } else if (schema['additionalProperties'] == false) {
            errors.add('$path.$key is not allowed.');
          }
        }
      }
    }
  }

  bool _matchesType(Object? value, String type) => switch (type) {
    'object' => value is Map,
    'array' => value is List,
    'string' => value is String,
    'integer' => value is int,
    'number' => value is num,
    'boolean' => value is bool,
    'null' => value == null,
    _ => throw FormatException('Unsupported schema type: $type'),
  };
}
