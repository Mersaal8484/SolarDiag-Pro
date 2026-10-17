import 'dart:convert';
import 'package:crypto/crypto.dart';

class RedactionChange {
  const RedactionChange({required this.kind, required this.placeholder});
  final String kind;
  final String placeholder;
}

class RedactionResult {
  const RedactionResult({required this.redacted, required this.changes});
  final String redacted;
  final List<RedactionChange> changes;
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
      RegExp(r'\b(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}\b', caseSensitive: false),
    ),
    ('ipv4', RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')),
    ('coordinate', RegExp(r'-?\d{1,3}\.\d{4,}\s*[,/]\s*-?\d{1,3}\.\d{4,}')),
    ('ssid', RegExp(r'\bssid\s*[:=]\s*[^\r\n,;]+', caseSensitive: false)),
    (
      'serial',
      RegExp(r'\b(serial|s/?n)\s*[:=]\s*[a-z0-9-]{5,}\b', caseSensitive: false),
    ),
    (
      'hostname',
      RegExp(r'\b(hostname|host)\s*[:=]\s*[a-z0-9._-]+', caseSensitive: false),
    ),
  ];

  RedactionResult redact(String input, {required String sessionSalt}) {
    var value = input;
    final changes = <RedactionChange>[];
    for (final (kind, pattern) in _patterns) {
      value = value.replaceAllMapped(pattern, (match) {
        final alias = _alias(kind, match.group(0)!, sessionSalt);
        changes.add(RedactionChange(kind: kind, placeholder: alias));
        return alias;
      });
    }
    value = _redactHexEmbedded(value, sessionSalt, changes);
    return RedactionResult(
      redacted: value,
      changes: List.unmodifiable(changes),
    );
  }

  String _redactHexEmbedded(
    String input,
    String salt,
    List<RedactionChange> changes,
  ) => input.replaceAllMapped(
    RegExp(r'\b(?:[0-9a-f]{2}){6,}\b', caseSensitive: false),
    (match) {
      final hex = match.group(0)!;
      try {
        final bytes = [
          for (var i = 0; i < hex.length; i += 2)
            int.parse(hex.substring(i, i + 2), radix: 16),
        ];
        final decoded = utf8.decode(bytes, allowMalformed: true);
        if (_patterns.any((entry) => entry.$2.hasMatch(decoded))) {
          final alias = _alias('encoded-sensitive', decoded, salt);
          changes.add(
            RedactionChange(kind: 'encoded-sensitive', placeholder: alias),
          );
          return utf8
              .encode(alias)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
        }
      } on FormatException {
        return hex;
      }
      return hex;
    },
  );

  String _alias(String kind, String value, String salt) =>
      '<REDACTED_${kind.toUpperCase()}_${sha256.convert(utf8.encode('$salt|$value')).toString().substring(0, 10)}>';
}
