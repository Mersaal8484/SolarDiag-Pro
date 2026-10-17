import 'offline_queue.dart';
import 'package.dart';

class MockContributionPortal implements ContributionPortal {
  final Map<String, ContributionPackage> submissions = {};
  final Set<String> withdrawn = {};
  bool failNextSubmission = false;
  @override
  Future<void> submit(String id, ContributionPackage package) async {
    if (failNextSubmission) {
      failNextSubmission = false;
      throw StateError('Simulated offline portal.');
    }
    submissions[id] = package;
  }

  @override
  Future<void> withdraw(String id) async {
    submissions.remove(id);
    withdrawn.add(id);
  }
}
