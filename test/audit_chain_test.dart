import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';

class _MemoryAuditStore implements AuditChainStore {
  List<AuditEntry>? storedEntries;
  String? storedHead;

  @override
  StoredAuditChain? load() {
    final entries = storedEntries;
    final head = storedHead;
    if (entries == null && head == null) return null;
    if (entries == null || head == null) {
      throw const FormatException('Incomplete audit store.');
    }
    return StoredAuditChain(entries: List.of(entries), head: head);
  }

  @override
  void saveEntries(List<AuditEntry> entries) =>
      storedEntries = List.of(entries);

  @override
  void saveHead(String head) => storedHead = head;
}

void main() {
  test('audit chain persists, restores and exports its separate head', () {
    final store = _MemoryAuditStore();
    final chain = AuditChain(clock: () => DateTime.utc(2026), store: store)
      ..append('finding_promoted', const {'id': 'f1'});

    final restored = AuditChain.load(store);
    expect(restored.verify(), isTrue);
    expect(restored.head, chain.head);
    expect(restored.export(), contains(chain.head));
    expect(store.storedHead, chain.head);
  });

  test('tampered audit entry is detected during load', () {
    final store = _MemoryAuditStore();
    AuditChain(
      clock: () => DateTime.utc(2026),
      store: store,
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
    expect(() => AuditChain.load(store), throwsFormatException);
  });

  test('tampered separately stored audit head is detected', () {
    final store = _MemoryAuditStore();
    AuditChain(
      clock: () => DateTime.utc(2026),
      store: store,
    ).append('finding_promoted', const {'id': 'f1'});
    store.storedHead = 'forged-head';
    expect(() => AuditChain.load(store), throwsFormatException);
  });
}
