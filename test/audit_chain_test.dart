import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';

class _MemoryAuditStore implements AuditChainStore {
  List<AuditEntry>? storedEntries;
  String? storedHead;
  String? storedMac;

  set chain(StoredAuditChain value) {
    storedEntries = List.of(value.entries);
    storedHead = value.head;
    storedMac = value.headMac;
  }

  @override
  StoredAuditChain? load() {
    final entries = storedEntries;
    final head = storedHead;
    if (entries == null && head == null) return null;
    if (entries == null || head == null) {
      throw const FormatException('Incomplete audit store.');
    }
    return StoredAuditChain(
      entries: List.of(entries),
      head: head,
      headMac: storedMac,
    );
  }

  @override
  void saveEntries(List<AuditEntry> entries) =>
      storedEntries = List.of(entries);

  @override
  void saveHead(String head) => storedHead = head;

  @override
  void saveHeadMac(String head, String mac) => storedMac = mac;
}

void main() {
  test('audit chain persists, restores and exports its separate head', () {
    final store = _MemoryAuditStore();
    final secretStore = InMemorySecretStore();
    final chain = AuditChain(
      clock: () => DateTime.utc(2026),
      store: store,
      secretStore: secretStore,
    )..append('finding_promoted', const {'id': 'f1'});

    final restored = AuditChain.load(store, secretStore: secretStore);
    expect(restored.verify(), isTrue);
    expect(restored.head, chain.head);
    expect(restored.export(), contains(chain.head));
    expect(store.storedHead, chain.head);
  });

  test('tampered audit entry is detected during load', () {
    final store = _MemoryAuditStore();
    final secretStore = InMemorySecretStore();
    AuditChain(
      clock: () => DateTime.utc(2026),
      store: store,
      secretStore: secretStore,
    ).append('finding_promoted', const {'id': 'f1'});
    final original = store.storedEntries!.single;
    store.storedEntries = [
      AuditEntry(
        sequence: original.sequence,
        timestamp: original.timestamp,
        action: original.action,
        details: const {'id': 'tampered'},
        previousHash: original.previousHash,
        hash: original.hash,
      ),
    ];
    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );
  });

  test('tampered separately stored audit head is detected', () {
    final store = _MemoryAuditStore();
    final secretStore = InMemorySecretStore();
    AuditChain(
      clock: () => DateTime.utc(2026),
      store: store,
      secretStore: secretStore,
    ).append('finding_promoted', const {'id': 'f1'});
    store.storedHead = 'forged-head';
    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );
  });

  test('missing audit head MAC is rejected when loading', () {
    final store = _MemoryAuditStore();
    final secretStore = InMemorySecretStore();
    AuditChain(
      store: store,
      secretStore: secretStore,
    ).append('finding_promoted', const {'id': 'f1'});
    store.storedMac = null;

    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );
  });

  test('valid stored MAC loads as unavailable when the key is missing', () {
    final store = _MemoryAuditStore();
    final secretStore = InMemorySecretStore();
    AuditChain(
      store: store,
      secretStore: secretStore,
    ).append('finding_promoted', const {'id': 'f1'});

    final restored = AuditChain.load(store);
    expect(restored.entries, hasLength(1));
    expect(restored.availability, AuditAvailability.keyUnavailable);
    restored.append('unsigned_in_memory', const {});
    expect(restored.availability, AuditAvailability.keyUnavailable);
    expect(store.storedEntries, hasLength(1));
  });

  test('stored empty genesis chain without a MAC is rejected', () {
    final store = _MemoryAuditStore()
      ..chain = const StoredAuditChain(entries: [], head: 'GENESIS');

    expect(
      () => AuditChain.load(store, secretStore: InMemorySecretStore()),
      throwsFormatException,
    );
  });

  test('audit append stays in memory without a secret store', () {
    final store = _MemoryAuditStore();
    final chain = AuditChain(store: store);

    chain.append('finding_promoted', const {'id': 'f1'});
    expect(chain.availability, AuditAvailability.keyUnavailable);
    expect(chain.entries, hasLength(1));
    expect(store.storedEntries, isNull);
    expect(store.storedHead, isNull);
  });

  test('replacing entries and head without the secret is rejected', () {
    final store = _MemoryAuditStore();
    final secretStore = InMemorySecretStore();
    AuditChain(
      store: store,
      secretStore: secretStore,
    ).append('finding_promoted', const {'id': 'f1'});
    final originalMac = store.storedMac;
    final replacement = AuditChain()
      ..append('replacement', const {'id': 'forged'});
    store.storedEntries = replacement.entries;
    store.storedHead = replacement.head;
    store.storedMac = originalMac;

    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );
  });

  test('file store rejects invalid MAC, missing MAC, and full replacement', () {
    final directory = Directory.systemTemp.createTempSync('audit-chain-test-');
    addTearDown(() {
      directory.deleteSync(recursive: true);
    });
    final entriesPath = '${directory.path}\\entries.json';
    final headPath = '${directory.path}\\head';
    final macPath = '$headPath.mac';
    final secretStore = InMemorySecretStore();
    final store = FileAuditChainStore(
      entriesPath: entriesPath,
      headPath: headPath,
    );
    AuditChain(store: store, secretStore: secretStore).append(
      'original',
      const {},
    );
    final originalMac = File(macPath).readAsStringSync();

    File(macPath).writeAsStringSync('invalid');
    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );

    File(macPath).deleteSync();
    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );

    final replacementEntriesPath = '${directory.path}\\replacement.json';
    final replacementHeadPath = '${directory.path}\\replacement-head';
    final replacementStore = FileAuditChainStore(
      entriesPath: replacementEntriesPath,
      headPath: replacementHeadPath,
    );
    AuditChain(
      store: replacementStore,
      secretStore: secretStore,
    ).append('replacement', const {});
    File(macPath).writeAsStringSync(originalMac);
    File(entriesPath).writeAsStringSync(
      File(replacementEntriesPath).readAsStringSync(),
    );
    File(headPath).writeAsStringSync(
      File(replacementHeadPath).readAsStringSync(),
    );
    expect(
      () => AuditChain.load(store, secretStore: secretStore),
      throwsFormatException,
    );
  });
}
