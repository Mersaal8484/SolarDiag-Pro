import 'dart:convert';

import 'package:crypto/crypto.dart';

class RedactionChange {
  const RedactionChange({required this.kind, required this.placeholder});
  final String kind;
  final String placeholder;
}

class RedactionResult {
  const RedactionResult({
    required this.redacted,
    required this.changes,
    required this.manualReviewRequired,
    required this.remainingDetections,
  });
  final String redacted;
  final List<RedactionChange> changes;
  final bool manualReviewRequired;
  final List<String> remainingDetections;
}

class ContributionRedactor {
  const ContributionRedactor();

  static final _patterns = <(String, RegExp)>[
    (
      'credential',
      RegExp(
        r'(password|passwd|pwd|token|secret|service[_ -]?key)\s*[:=]\s*[^\s,;]+',
        caseSensitive: false,
      ),
    ),
    (
      'mac',
      RegExp(
        r'\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b|\b[0-9a-f]{12}\b',
        caseSensitive: false,
      ),
    ),
    ('ipv4', RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')),
    (
      'ipv6',
      RegExp(
        r'\b(?=[0-9a-f:]*[0-9a-f])(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}\b',
        caseSensitive: false,
      ),
    ),
    ('coordinate', RegExp(r'-?\d{1,3}\.\d{4,}\s*[,/]\s*-?\d{1,3}\.\d{4,}')),
    ('ssid', RegExp(r'\bssid\s*[:=]\s*[^\r\n,;]+', caseSensitive: false)),
    (
      'serial',
      RegExp(
        r'\b(serial|s/?n|barcode)\s*[:=]\s*[a-z0-9-]{5,}\b',
        caseSensitive: false,
      ),
    ),
    (
      'bare-serial',
      RegExp(
        r'\b(?=[a-z0-9-]{10,}\b)(?=[a-z0-9-]*[a-z])(?=[a-z0-9-]*\d)[a-z0-9-]+\b',
        caseSensitive: false,
      ),
    ),
    (
      'hostname',
      RegExp(r'\b(hostname|host)\s*[:=]\s*[a-z0-9._-]+', caseSensitive: false),
    ),
  ];

  RedactionResult redact(
    String input, {
    required String sessionSalt,
    Iterable<String> denyList = const [],
  }) {
    var value = _normalizeArabicIndicDigits(input);
    final changes = <RedactionChange>[];
    final patterns = [
      ..._patterns,
      for (final denied in denyList.where((item) => item.trim().isNotEmpty))
        (
          'deny-list',
          RegExp(RegExp.escape(denied.trim()), caseSensitive: false),
        ),
    ];
    value = _applyPatterns(value, patterns, sessionSalt, changes);
    value = _redactEncoded(value, patterns, sessionSalt, changes);
    final remaining = _detect(value, patterns);
    return RedactionResult(
      redacted: value,
      changes: List.unmodifiable(changes),
      manualReviewRequired: remaining.isNotEmpty,
      remainingDetections: List.unmodifiable(remaining),
    );
  }

  String _applyPatterns(
    String input,
    List<(String, RegExp)> patterns,
    String salt,
    List<RedactionChange> changes,
  ) {
    var value = input;
    for (final (kind, pattern) in patterns) {
      value = value.replaceAllMapped(pattern, (match) {
        final alias = _alias(kind, match.group(0)!, salt);
        changes.add(RedactionChange(kind: kind, placeholder: alias));
        return alias;
      });
    }
    return value;
  }

  String _redactEncoded(
    String input,
    List<(String, RegExp)> patterns,
    String salt,
    List<RedactionChange> changes,
  ) {
    var value = input.replaceAllMapped(
      RegExp(r'\b(?:[0-9a-f]{2}){6,}\b', caseSensitive: false),
      (match) => _replaceDecoded(
        match.group(0)!,
        'hex',
        () {
          final hex = match.group(0)!;
          return utf8.decode([
            for (var i = 0; i < hex.length; i += 2)
              int.parse(hex.substring(i, i + 2), radix: 16),
          ], allowMalformed: true);
        },
        patterns,
        salt,
        changes,
      ),
    );
    value = value.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9+/]{16,}={0,2}\b'),
      (match) => _replaceDecoded(
        match.group(0)!,
        'base64',
        () => utf8.decode(base64Decode(match.group(0)!)),
        patterns,
        salt,
        changes,
      ),
    );
    return value.replaceAllMapped(
      RegExp(r'(?:%[0-9a-fA-F]{2}){4,}'),
      (match) => _replaceDecoded(
        match.group(0)!,
        'url-encoded',
        () => Uri.decodeComponent(match.group(0)!),
        patterns,
        salt,
        changes,
      ),
    );
  }

  String _replaceDecoded(
    String original,
    String encoding,
    String Function() decode,
    List<(String, RegExp)> patterns,
    String salt,
    List<RedactionChange> changes,
  ) {
    try {
      final decoded = _normalizeArabicIndicDigits(decode());
      if (patterns.any((entry) => entry.$2.hasMatch(decoded))) {
        final alias = _alias('encoded-sensitive', decoded, salt);
        changes.add(
          RedactionChange(
            kind: 'encoded-sensitive-$encoding',
            placeholder: alias,
          ),
        );
        return alias;
      }
    } on FormatException {
      return original;
    }
    return original;
  }

  List<String> _detect(String input, List<(String, RegExp)> patterns) {
    final withoutAliases = input.replaceAll(
      RegExp(r'<REDACTED_[A-Z0-9-]+_[a-f0-9]{32}>'),
      '',
    );
    final detections = [
      for (final (kind, pattern) in patterns)
        if (pattern.hasMatch(withoutAliases)) kind,
    ];
    if (RegExp(
      r'-----BEGIN [A-Z ]*PRIVATE KEY-----',
    ).hasMatch(withoutAliases)) {
      detections.add('private-key-material');
    }
    return detections;
  }

  String _alias(String kind, String value, String salt) =>
      '<REDACTED_${kind.toUpperCase()}_${sha256.convert(utf8.encode('$salt|$value')).toString().substring(0, 32)}>';

  String _normalizeArabicIndicDigits(String input) {
    const source = '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹';
    const target = '01234567890123456789';
    return input.split('').map((character) {
      final index = source.indexOf(character);
      return index < 0 ? character : target[index];
    }).join();
  }
}
