import 'dart:convert';
import 'dart:io';

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

  Map<String, Object?> toJson() => {
    'sequence': sequence,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'action': action,
    'details': details,
    'previous_hash': previousHash,
    'hash': hash,
  };

  factory AuditEntry.fromJson(Map<String, Object?> json) {
    final sequence = json['sequence'];
    final timestamp = json['timestamp'];
    final action = json['action'];
    final details = json['details'];
    final previousHash = json['previous_hash'];
    final hash = json['hash'];
    if (sequence is! int ||
        timestamp is! String ||
        action is! String ||
        details is! Map ||
        previousHash is! String ||
        hash is! String) {
      throw const FormatException('Invalid audit entry.');
    }
    return AuditEntry(
      sequence: sequence,
      timestamp: DateTime.parse(timestamp),
      action: action,
      details: Map<String, Object?>.unmodifiable(
        Map<String, Object?>.from(details),
      ),
      previousHash: previousHash,
      hash: hash,
    );
  }
}

class StoredAuditChain {
  const StoredAuditChain({required this.entries, required this.head});
  final List<AuditEntry> entries;
  final String head;
}

abstract interface class AuditChainStore {
  void saveEntries(List<AuditEntry> entries);
  void saveHead(String head);
  StoredAuditChain? load();
}

class FileAuditChainStore implements AuditChainStore {
  const FileAuditChainStore({
    required this.entriesPath,
    required this.headPath,
  });
  final String entriesPath;
  final String headPath;

  @override
  StoredAuditChain? load() {
    final entriesFile = File(entriesPath);
    final headFile = File(headPath);
    if (!entriesFile.existsSync() && !headFile.existsSync()) {
      return null;
    }
    if (!entriesFile.existsSync() || !headFile.existsSync()) {
      throw const FormatException('Audit entries and head must both exist.');
    }
    final decoded = jsonDecode(entriesFile.readAsStringSync());
    if (decoded is! List) {
      throw const FormatException('Audit store must contain an array.');
    }
    return StoredAuditChain(
      entries: [
        for (final value in decoded)
          AuditEntry.fromJson(Map<String, Object?>.from(value as Map)),
      ],
      head: headFile.readAsStringSync().trim(),
    );
  }

  @override
  void saveEntries(List<AuditEntry> entries) {
    final file = File(entriesPath);
    file.parent.createSync(recursive: true);
    final temporary = File('$entriesPath.tmp');
    temporary.writeAsStringSync(
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
      flush: true,
    );
    temporary.renameSync(entriesPath);
  }

  @override
  void saveHead(String head) {
    final file = File(headPath);
    file.parent.createSync(recursive: true);
    final temporary = File('$headPath.tmp');
    temporary.writeAsStringSync(head, flush: true);
    temporary.renameSync(headPath);
  }
}

class AuditChain {
  AuditChain({DateTime Function()? clock, this._store})
    : _clock = clock ?? DateTime.now,
      _entries = [];

  AuditChain._(this._clock, this._store, this._entries);

  final DateTime Function() _clock;
  final AuditChainStore? _store;
  List<AuditEntry> _entries;
  List<AuditEntry> get entries => List.unmodifiable(_entries);
  String get head => _entries.isEmpty ? 'GENESIS' : _entries.last.hash;

  factory AuditChain.load(AuditChainStore store, {DateTime Function()? clock}) {
    final stored = store.load();
    if (stored == null) {
      return AuditChain(clock: clock, store: store);
    }
    final chain = AuditChain._(
      clock ?? DateTime.now,
      store,
      List.of(stored.entries),
    );
    if (!chain.verify() || stored.head != chain.head) {
      throw const FormatException('Audit chain tampering detected.');
    }
    return chain;
  }

  AuditEntry append(String action, Map<String, Object?> details) {
    final timestamp = _clock().toUtc();
    final sequence = _entries.length;
    final previousHash = head;
    final payload = _payload(
      sequence,
      timestamp,
      action,
      details,
      previousHash,
    );
    final entry = AuditEntry(
      sequence: sequence,
      timestamp: timestamp,
      action: action,
      details: Map.unmodifiable(details),
      previousHash: previousHash,
      hash: sha256.convert(utf8.encode(payload)).toString(),
    );
    _entries.add(entry);
    _store?.saveEntries(entries);
    _store?.saveHead(head);
    return entry;
  }

  bool verify() {
    var previous = 'GENESIS';
    for (var index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      if (entry.sequence != index || entry.previousHash != previous) {
        return false;
      }
      final payload = _payload(
        entry.sequence,
        entry.timestamp,
        entry.action,
        entry.details,
        entry.previousHash,
      );
      if (sha256.convert(utf8.encode(payload)).toString() != entry.hash) {
        return false;
      }
      previous = entry.hash;
    }
    return true;
  }

  String export() => jsonEncode({
    'schema_version': 1,
    'head': head,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  });

  static String _payload(
    int sequence,
    DateTime timestamp,
    String action,
    Map<String, Object?> details,
    String previousHash,
  ) =>
      '$sequence|${timestamp.toUtc().toIso8601String()}|$action|${_canonical(details)}|$previousHash';

  static String _canonical(Map<String, Object?> details) {
    Object? normalize(Object? value) {
      if (value is Map) {
        final keys = value.keys.map((key) => key.toString()).toList()..sort();
        return {for (final key in keys) key: normalize(value[key])};
      }
      if (value is List) {
        return value.map(normalize).toList();
      }
      return value;
    }

    return jsonEncode(normalize(details));
  }
}
