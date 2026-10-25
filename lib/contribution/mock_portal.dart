import '../trust/signed_tokens.dart';
import 'offline_queue.dart';
import 'package.dart';
import 'platform_api.dart';

class MockContributionPortal
    implements ContributionPortal, ContributionPlatformApi {
  final Map<String, ContributionPackage> submissions = {};
  final Set<String> withdrawn = {};
  final Map<String, String> lifecycleStages = {};
  final Map<String, List<String>> analystFindings = {};
  final List<String> operationLog = [];
  final Map<LibraryChannel, LibraryPack> libraryPacks = {};
  final Map<String, EntitlementToken> entitlements = {};
  RevocationList? revocations;
  bool failNextSubmission = false;

  @override
  Set<String> get supportedOperationIds => ContributionPlatformOperations.all;

  @override
  Future<void> submit(String id, ContributionPackage package) =>
      submitContribution(id, package);

  @override
  Future<void> submitContribution(
    String id,
    ContributionPackage package,
  ) async {
    if (failNextSubmission) {
      failNextSubmission = false;
      throw StateError('Simulated offline portal.');
    }
    submissions[id] = package;
    lifecycleStages[id] = 'submitted';
    operationLog.add('submitContribution:$id');
  }

  @override
  Future<ContributionPackage?> getContribution(String id) async {
    operationLog.add('getContribution:$id');
    return submissions[id];
  }

  @override
  Future<void> withdraw(String id) => withdrawContribution(id);

  @override
  Future<void> withdrawContribution(String id) async {
    submissions.remove(id);
    withdrawn.add(id);
    lifecycleStages[id] = 'withdrawn';
    operationLog.add('withdrawContribution:$id');
  }

  @override
  Future<void> advanceContributionLifecycle(
    String id,
    String targetStage,
  ) async {
    _requireSubmission(id);
    lifecycleStages[id] = targetStage;
    operationLog.add('advanceContributionLifecycle:$id:$targetStage');
  }

  @override
  Future<void> quarantineContribution(
    String id, {
    required bool accepted,
  }) async {
    _requireSubmission(id);
    lifecycleStages[id] = accepted ? 'sanitized' : 'quarantined';
    operationLog.add('quarantineContribution:$id:$accepted');
  }

  @override
  Future<void> triageContribution(String id, String note) async {
    _requireSubmission(id);
    lifecycleStages[id] = 'triage';
    operationLog.add('triageContribution:$id:$note');
  }

  @override
  Future<void> recordAnalystFinding(String id, String finding) async {
    _requireSubmission(id);
    analystFindings.putIfAbsent(id, () => []).add(finding);
    lifecycleStages[id] = 'analysis';
    operationLog.add('recordAnalystFinding:$id');
  }

  @override
  Future<void> approveContribution(String id) async {
    _requireSubmission(id);
    lifecycleStages[id] = 'approved';
    operationLog.add('approveContribution:$id');
  }

  @override
  Future<void> signContribution(String id) async {
    _requireSubmission(id);
    lifecycleStages[id] = 'signed';
    operationLog.add('signContribution:$id');
  }

  @override
  Future<LibraryPack?> getLatestLibraryPack(
    LibraryChannel channel, {
    int? installedVersion,
  }) async {
    operationLog.add('getLatestLibraryPack:${channel.name}');
    final pack = libraryPacks[channel];
    return pack != null &&
            (installedVersion == null || pack.version > installedVersion)
        ? pack
        : null;
  }

  @override
  Future<RevocationList?> getRevocations() async {
    operationLog.add('getRevocations');
    return revocations;
  }

  @override
  Future<EntitlementToken?> getEntitlement(String subject) async {
    operationLog.add('getEntitlement:$subject');
    return entitlements[subject];
  }

  void _requireSubmission(String id) {
    if (!submissions.containsKey(id)) {
      throw StateError('Unknown contribution: $id.');
    }
  }
}
