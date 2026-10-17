class FeatureFlags {
  const FeatureFlags({
    this.studioEnabled = false,
    this.contributionsEnabled = false,
    this.libraryCloudSync = false,
  });
  final bool studioEnabled;
  final bool contributionsEnabled;
  final bool libraryCloudSync;
}
