# R5-2 Repair 6

- Status: NOT RUN — no Flutter/Dart checks or tools were run.
- M1: Removed the redundant nullable assertion; used an initializing formal for the public `auditSecretStore` parameter to preserve existing callers (the private name cannot be used across Dart libraries).
- M3 assertion: `content.contains('ConfirmationToken('), isFalse,` — the current screen already used the factory, so that literal was absent; removed the remaining type mention too, leaving only factory calls in the feature.
- M4 assertion: `expect(profileResearch.hasWriteCapability, isTrue,` — parsing previously failed first because the fixture omitted required parser fields and used inferred maps; supplied required fields and explicit object-map types.
- M5 assertion: `() => AuditChain.load(store, secretStore: secretStore),` with `throwsFormatException` — the fake returned its stale stored MAC, ignoring the changed `savedMac`; `load()` now returns the current MAC value.
- Audit load continues to reject absent/invalid MACs with a usable key; missing key remains `keyUnavailable`.
- Checked all `DeviceSession` secret-store callers, audit-store/secret-store implementations, and token-construction sites in `lib/` and `test/`.
- Owner must run: `dart format lib test tool`; `flutter analyze --fatal-infos`; `flutter test`.
- Compile correctness and test results remain unverified by design.
