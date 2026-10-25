import '../trust/signed_tokens.dart';
import 'package.dart';

abstract final class ContributionPlatformOperations {
  static const all = <String>{
    'submitContribution',
    'getContribution',
    'withdrawContribution',
    'advanceContributionLifecycle',
    'quarantineContribution',
    'triageContribution',
    'recordAnalystFinding',
    'approveContribution',
    'signContribution',
    'getLatestLibraryPack',
    'getRevocations',
    'getEntitlement',
  };
}

abstract interface class ContributionPlatformApi {
  Set<String> get supportedOperationIds;

  Future<void> submitContribution(String id, ContributionPackage package);
  Future<ContributionPackage?> getContribution(String id);
  Future<void> withdrawContribution(String id);
  Future<void> advanceContributionLifecycle(String id, String targetStage);
  Future<void> quarantineContribution(String id, {required bool accepted});
  Future<void> triageContribution(String id, String note);
  Future<void> recordAnalystFinding(String id, String finding);
  Future<void> approveContribution(String id);
  Future<void> signContribution(String id);
  Future<LibraryPack?> getLatestLibraryPack(
    LibraryChannel channel, {
    int? installedVersion,
  });
  Future<RevocationList?> getRevocations();
  Future<EntitlementToken?> getEntitlement(String subject);
}
