import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

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
  const StoredAuditChain({
    required this.entries,
    required this.head,
    this.headMac,
  });
  final List<AuditEntry> entries;
  final String head;
  final String? headMac;
}

enum AuditAvailability { available, keyUnavailable }

abstract interface class SecretStore {
  Future<List<int>> getOrCreateSecret(String keyId);
  List<int> getOrCreateSecretSync(String keyId);
}

@visibleForTesting
class InMemorySecretStore implements SecretStore {
  InMemorySecretStore([Map<String, List<int>>? initial])
    : _secrets = initial ?? {};
  final Map<String, List<int>> _secrets;

  void setSecret(String keyId, Object secret) {
    if (secret is String) {
      _secrets[keyId] = utf8.encode(secret);
    } else if (secret is List<int>) {
      _secrets[keyId] = secret;
    }
  }

  @override
  Future<List<int>> getOrCreateSecret(String keyId) async =>
      getOrCreateSecretSync(keyId);

  @override
  List<int> getOrCreateSecretSync(String keyId) =>
      _secrets.putIfAbsent(keyId, () {
        final rng = Random.secure();
        return List<int>.generate(32, (_) => rng.nextInt(256));
      });
}

abstract interface class AuditChainStore {
  void saveEntries(List<AuditEntry> entries);
  void saveHead(String head);
  void saveHeadMac(String head, String mac);
  StoredAuditChain? load();
}

class FileAuditChainStore implements AuditChainStore {
  FileAuditChainStore({
    required this.entriesPath,
    required this.headPath,
    String? macPath,
    this.secretStore,
    this.keyId = 'installation_audit_key',
  }) : macPath = macPath ?? '$headPath.mac';

  final String entriesPath;
  final String headPath;
  final String macPath;
  final SecretStore? secretStore;
  final String keyId;

  @override
  StoredAuditChain? load() {
    final entriesFile = File(entriesPath);
    final headFile = File(headPath);
    final macFile = File(macPath);
    if (!entriesFile.existsSync() &&
        !headFile.existsSync() &&
        !macFile.existsSync()) {
      return null;
    }
    if (!entriesFile.existsSync() || !headFile.existsSync()) {
      throw const FormatException('Audit entries and head must both exist.');
    }
    final decoded = jsonDecode(entriesFile.readAsStringSync());
    if (decoded is! List) {
      throw const FormatException('Audit store must contain an array.');
    }
    final head = headFile.readAsStringSync().trim();
    String? mac;
    if (macFile.existsSync()) {
      mac = macFile.readAsStringSync().trim();
    }
    return StoredAuditChain(
      entries: [
        for (final value in decoded)
          AuditEntry.fromJson(Map<String, Object?>.from(value as Map)),
      ],
      head: head,
      headMac: mac,
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
    if (secretStore != null) {
      final secret = secretStore!.getOrCreateSecretSync(keyId);
      final mac = Hmac(sha256, secret).convert(utf8.encode(head)).toString();
      saveHeadMac(head, mac);
    }
  }

  @override
  void saveHeadMac(String head, String mac) {
    final file = File(macPath);
    file.parent.createSync(recursive: true);
    final temporary = File('$macPath.tmp');
    temporary.writeAsStringSync(mac, flush: true);
    temporary.renameSync(macPath);
  }
}

class AuditChain {
  AuditChain({
    DateTime Function()? clock,
    AuditChainStore? store,
    this.secretStore,
    this.keyId = 'installation_audit_key',
  }) : _clock = clock ?? DateTime.now,
       // Keep the public `store:` parameter instead of exposing a private
       // field name through the constructor API.
       // ignore: prefer_initializing_formals
       _store = store,
       _entries = [];

  factory AuditChain.inMemory({
    DateTime Function()? clock,
    SecretStore? secretStore,
    String keyId = 'installation_audit_key',
  }) => AuditChain(clock: clock, secretStore: secretStore, keyId: keyId);

  AuditChain._(
    this._clock,
    this._store,
    this._entries,
    this.secretStore,
    this.keyId,
  );

  final DateTime Function() _clock;
  final AuditChainStore? _store;
  final SecretStore? secretStore;
  final String keyId;
  List<AuditEntry> _entries;
  bool _hasUnsignedEntries = false;
  List<AuditEntry> get entries => List.unmodifiable(_entries);
  String get head => _entries.isEmpty ? 'GENESIS' : _entries.last.hash;
  bool get hasUnsignedEntries => _hasUnsignedEntries;
  AuditAvailability get availability {
    if (_hasUnsignedEntries) return AuditAvailability.keyUnavailable;
    final store = secretStore;
    if (store == null) return AuditAvailability.keyUnavailable;
    try {
      return store.getOrCreateSecretSync(keyId).length >= 32
          ? AuditAvailability.available
          : AuditAvailability.keyUnavailable;
    } on StateError {
      return AuditAvailability.keyUnavailable;
    }
  }

  factory AuditChain.load(
    AuditChainStore store, {
    DateTime Function()? clock,
    SecretStore? secretStore,
    String keyId = 'installation_audit_key',
  }) {
    final stored = store.load();
    if (stored == null) {
      return AuditChain(
        clock: clock,
        store: store,
        secretStore: secretStore,
        keyId: keyId,
      );
    }
    final chain = AuditChain._(
      clock ?? DateTime.now,
      store,
      List.of(stored.entries),
      secretStore,
      keyId,
    );
    if (!chain.verify() || stored.head != chain.head) {
      throw const FormatException('Audit chain tampering detected.');
    }
    final mac = stored.headMac;
    if (mac == null || mac.isEmpty) {
      throw const FormatException('Audit head MAC is required.');
    }
    final storeSecret = secretStore;
    if (storeSecret == null) {
      chain._hasUnsignedEntries = true;
      return chain;
    }
    late final List<int> secret;
    try {
      secret = storeSecret.getOrCreateSecretSync(keyId);
    } on StateError {
      chain._hasUnsignedEntries = true;
      return chain;
    }
    if (secret.length < 32) {
      chain._hasUnsignedEntries = true;
      return chain;
    }
    final expectedMac = Hmac(
      sha256,
      secret,
    ).convert(utf8.encode(stored.head)).toString();
    if (mac != expectedMac) {
      throw const FormatException('Audit head MAC verification failed.');
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
    final store = _store;
    List<int>? secret;
    if (!_hasUnsignedEntries) {
      try {
        final candidate = secretStore?.getOrCreateSecretSync(keyId);
        if (candidate != null && candidate.length >= 32) secret = candidate;
      } on StateError {
        secret = null;
      }
    }
    final keyAvailable = secret != null;
    if (!keyAvailable) _hasUnsignedEntries = true;
    final persistentMac = store == null || secret == null
        ? null
        : Hmac(sha256, secret).convert(utf8.encode(entry.hash)).toString();
    _entries.add(entry);
    if (store != null && persistentMac != null) {
      store.saveEntries(entries);
      store.saveHead(entry.hash);
      store.saveHeadMac(entry.hash, persistentMac);
    }
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

  String computeHeadHmac() {
    if (secretStore == null) {
      throw StateError('Cannot compute HMAC without secretStore');
    }
    final secret = secretStore!.getOrCreateSecretSync(keyId);
    return Hmac(sha256, secret).convert(utf8.encode(head)).toString();
  }

  bool verifyHeadHmac(String mac) {
    if (secretStore == null) return false;
    final expected = computeHeadHmac();
    return mac == expected;
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
