import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuditEntry {
  const AuditEntry({
    required this.sequence,
    required this.timestamp,
    required this.action,
    required this.details,
    required this.previousHash,
    required this.hash,
  });
  final int sequence;
  final DateTime timestamp;
  final String action;
  final Map<String, Object?> details;
  final String previousHash;
  final String hash;
}

class AuditChain {
  AuditChain({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final List<AuditEntry> _entries = [];
  List<AuditEntry> get entries => List.unmodifiable(_entries);
  String get head => _entries.isEmpty ? 'GENESIS' : _entries.last.hash;

  AuditEntry append(String action, Map<String, Object?> details) {
    final timestamp = _clock().toUtc();
    final sequence = _entries.length;
    final previousHash = head;
    final canonicalDetails = _canonical(details);
    final payload =
        '$sequence|${timestamp.toIso8601String()}|$action|$canonicalDetails|$previousHash';
    final hash = sha256.convert(utf8.encode(payload)).toString();
    final entry = AuditEntry(
      sequence: sequence,
      timestamp: timestamp,
      action: action,
      details: Map.unmodifiable(details),
      previousHash: previousHash,
      hash: hash,
    );
    _entries.add(entry);
    return entry;
  }

  bool verify() {
    var previous = 'GENESIS';
    for (final entry in _entries) {
      if (entry.previousHash != previous) return false;
      final payload =
          '${entry.sequence}|${entry.timestamp.toIso8601String()}|${entry.action}|${_canonical(entry.details)}|${entry.previousHash}';
      if (sha256.convert(utf8.encode(payload)).toString() != entry.hash) {
        return false;
      }
      previous = entry.hash;
    }
    return true;
  }

  static String _canonical(Map<String, Object?> details) {
    final keys = details.keys.toList()..sort();
    return jsonEncode({for (final key in keys) key: details[key]});
  }
}
