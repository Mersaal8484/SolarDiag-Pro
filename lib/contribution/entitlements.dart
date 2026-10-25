import '../trust/signed_tokens.dart';

class EntitlementPolicy {
  EntitlementPolicy._({
    required this.schemaVersion,
    required this.safetyCriticalFeatures,
    required this.freeFeatures,
    required this.paidFeatures,
  });

  final int schemaVersion;
  final Set<String> safetyCriticalFeatures;
  final Set<String> freeFeatures;
  final Set<String> paidFeatures;

  static const mandatorySafetyFeatures = <String>{
    'active_alarms',
    'protection_states',
    'safety_warnings',
    'read_only_monitoring',
  };

  factory EntitlementPolicy.fromJson(Map<String, Object?> json) {
    Set<String> featureSet(String key) {
      final value = json[key];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('$key must be a list of feature identifiers.');
      }
      return Set.unmodifiable(value.cast<String>());
    }

    final schemaVersion = json['schema_version'];
    if (schemaVersion is! int || schemaVersion < 1) {
      throw const FormatException('schema_version must be a positive integer.');
    }
    final safety = featureSet('safety_critical_features');
    final free = featureSet('free_features');
    final paid = featureSet('paid_features');
    if (!safety.containsAll(mandatorySafetyFeatures) ||
        free.intersection(paid).isNotEmpty) {
      throw const FormatException(
        'Mandatory safety features are required and free/paid features '
        'must be disjoint.',
      );
    }
    return EntitlementPolicy._(
      schemaVersion: schemaVersion,
      safetyCriticalFeatures: safety,
      freeFeatures: free,
      paidFeatures: paid,
    );
  }

  bool isSafetyCritical(String feature) =>
      safetyCriticalFeatures.contains(feature);
}

class EntitlementAccessController {
  const EntitlementAccessController({
    required this.policy,
    required this.validator,
  });

  final EntitlementPolicy policy;
  final EntitlementValidator validator;

  Future<bool> canAccess({
    required String feature,
    required DateTime now,
    EntitlementToken? token,
  }) async {
    if (policy.isSafetyCritical(feature) ||
        policy.freeFeatures.contains(feature)) {
      return true;
    }
    if (!policy.paidFeatures.contains(feature) || token == null) return false;
    return validator.permits(token, feature, now);
  }
}
