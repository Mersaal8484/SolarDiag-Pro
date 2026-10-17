import 'package.dart';

enum QueueState { queued, uploading, submitted, failed, withdrawn }

class QueuedContribution {
  const QueuedContribution({
    required this.id,
    required this.package,
    required this.state,
    required this.attempts,
    this.lastError,
  });
  final String id;
  final ContributionPackage package;
  final QueueState state;
  final int attempts;
  final String? lastError;
  QueuedContribution copyWith({
    QueueState? state,
    int? attempts,
    String? lastError,
  }) => QueuedContribution(
    id: id,
    package: package,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError,
  );
}

abstract interface class ContributionPortal {
  Future<void> submit(String id, ContributionPackage package);
  Future<void> withdraw(String id);
}

class OfflineContributionQueue {
  final Map<String, QueuedContribution> _items = {};
  List<QueuedContribution> get items => List.unmodifiable(_items.values);
  void enqueue(String id, ContributionPackage package) {
    if (_items.containsKey(id)) throw StateError('Duplicate contribution id.');
    _items[id] = QueuedContribution(
      id: id,
      package: package,
      state: QueueState.queued,
      attempts: 0,
    );
  }

  Future<void> flush(ContributionPortal portal) async {
    for (final item in [..._items.values]) {
      if (item.state != QueueState.queued && item.state != QueueState.failed) {
        continue;
      }
      _items[item.id] = item.copyWith(
        state: QueueState.uploading,
        attempts: item.attempts + 1,
      );
      try {
        await portal.submit(item.id, item.package);
        _items[item.id] = _items[item.id]!.copyWith(
          state: QueueState.submitted,
        );
      } catch (error) {
        _items[item.id] = _items[item.id]!.copyWith(
          state: QueueState.failed,
          lastError: error.runtimeType.toString(),
        );
      }
    }
  }

  Future<void> withdraw(String id, ContributionPortal portal) async {
    final item = _items[id];
    if (item == null) throw StateError('Unknown contribution.');
    if (item.state == QueueState.submitted) await portal.withdraw(id);
    _items[id] = item.copyWith(state: QueueState.withdrawn);
  }
}
