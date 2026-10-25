import 'dart:convert';

import 'package:crypto/crypto.dart';

class RewardEvidence {
  const RewardEvidence({
    required this.evidenceQuality,
    this.newCoverage = false,
    this.reproducible = false,
    this.hardwareVerified = false,
    this.duplicateOf,
    this.falseData = false,
  }) : assert(evidenceQuality >= 0 && evidenceQuality <= 1);

  final double evidenceQuality;
  final bool newCoverage;
  final bool reproducible;
  final bool hardwareVerified;
  final String? duplicateOf;
  final bool falseData;
}

class RewardPolicy {
  const RewardPolicy({
    this.newCoveragePoints = 40,
    this.evidenceQualityPoints = 30,
    this.reproducibilityPoints = 20,
    this.hardwareVerificationPoints = 10,
    this.falseDataDeduction = 100,
    this.maximumPositiveEventsPerDay = 20,
    this.maximumPositivePointsPerDay = 500,
  });

  final int newCoveragePoints;
  final int evidenceQualityPoints;
  final int reproducibilityPoints;
  final int hardwareVerificationPoints;
  final int falseDataDeduction;
  final int maximumPositiveEventsPerDay;
  final int maximumPositivePointsPerDay;
}

class RewardLedgerEntry {
  const RewardLedgerEntry({
    required this.sequence,
    required this.contributionId,
    required this.contributorId,
    required this.occurredAt,
    required this.points,
    required this.reason,
    required this.previousHash,
    required this.hash,
  });

  final int sequence;
  final String contributionId;
  final String contributorId;
  final DateTime occurredAt;
  final int points;
  final String reason;
  final String previousHash;
  final String hash;

  Map<String, Object?> get payload => {
    'sequence': sequence,
    'contribution_id': contributionId,
    'contributor_id': contributorId,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'points': points,
    'reason': reason,
    'previous_hash': previousHash,
  };
}

class RewardLedger {
  RewardLedger({this.policy = const RewardPolicy()});

  static const genesisHash = 'GENESIS';

  final RewardPolicy policy;
  final List<RewardLedgerEntry> _entries = [];
  final Set<String> _recordedContributionIds = {};

  List<RewardLedgerEntry> get entries => List.unmodifiable(_entries);

  RewardLedgerEntry append({
    required String contributionId,
    required String contributorId,
    required DateTime occurredAt,
    required RewardEvidence evidence,
  }) {
    if (contributionId.trim().isEmpty || contributorId.trim().isEmpty) {
      throw ArgumentError(
        'Contribution and contributor identifiers are required.',
      );
    }
    if (evidence.evidenceQuality < 0 || evidence.evidenceQuality > 1) {
      throw RangeError.range(evidence.evidenceQuality, 0, 1, 'evidenceQuality');
    }
    if (!_recordedContributionIds.add(contributionId)) {
      throw StateError('A contribution can be assessed only once.');
    }

    final (points, reason) = _assess(
      contributorId: contributorId,
      occurredAt: occurredAt.toUtc(),
      evidence: evidence,
    );
    final previousHash = _entries.isEmpty ? genesisHash : _entries.last.hash;
    final payload = {
      'sequence': _entries.length + 1,
      'contribution_id': contributionId,
      'contributor_id': contributorId,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'points': points,
      'reason': reason,
      'previous_hash': previousHash,
    };
    final entry = RewardLedgerEntry(
      sequence: _entries.length + 1,
      contributionId: contributionId,
      contributorId: contributorId,
      occurredAt: occurredAt.toUtc(),
      points: points,
      reason: reason,
      previousHash: previousHash,
      hash: sha256.convert(utf8.encode(jsonEncode(payload))).toString(),
    );
    _entries.add(entry);
    return entry;
  }

  bool verifyIntegrity() {
    var previousHash = genesisHash;
    for (var index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      if (entry.sequence != index + 1 || entry.previousHash != previousHash) {
        return false;
      }
      final expected = sha256
          .convert(utf8.encode(jsonEncode(entry.payload)))
          .toString();
      if (entry.hash != expected) return false;
      previousHash = entry.hash;
    }
    return true;
  }

  (int, String) _assess({
    required String contributorId,
    required DateTime occurredAt,
    required RewardEvidence evidence,
  }) {
    if (evidence.falseData) {
      return (-policy.falseDataDeduction, 'false-data-deduction');
    }
    if (evidence.duplicateOf != null) return (0, 'duplicate');

    final sameDay = _entries.where(
      (entry) =>
          entry.contributorId == contributorId &&
          entry.occurredAt.year == occurredAt.year &&
          entry.occurredAt.month == occurredAt.month &&
          entry.occurredAt.day == occurredAt.day &&
          entry.points > 0,
    );
    if (sameDay.length >= policy.maximumPositiveEventsPerDay) {
      return (0, 'daily-event-rate-limit');
    }

    final raw =
        (evidence.newCoverage ? policy.newCoveragePoints : 0) +
        (policy.evidenceQualityPoints * evidence.evidenceQuality).round() +
        (evidence.reproducible ? policy.reproducibilityPoints : 0) +
        (evidence.hardwareVerified ? policy.hardwareVerificationPoints : 0);
    final awardedToday = sameDay.fold<int>(
      0,
      (sum, entry) => sum + entry.points,
    );
    final remaining = policy.maximumPositivePointsPerDay - awardedToday;
    if (remaining <= 0) return (0, 'daily-point-rate-limit');
    final awarded = raw > remaining ? remaining : raw;
    return (awarded, awarded == raw ? 'verified-value' : 'daily-point-cap');
  }
}
