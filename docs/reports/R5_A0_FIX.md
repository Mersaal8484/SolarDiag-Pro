# Repair A0-fix

NOT RUN — owner will verify.

- P1 root cause: session accesses targeted a static simulator identity through adapter instances.
- Added shared `DeviceProfileIdentity` to the adapter contract; both simulator adapters now expose instance getters.
- Session stores adapters through their interfaces and reads `profileId`, model, firmware, and device ID from the active adapter.
- Checked all `profileIdentity` uses and all `BmsAdapter`/`InverterAdapter` implementers in `lib/` and `test/`.
- P2: removed the four reported simulator imports; needed adapter symbols remain available through the write-pipeline library import.
- `lib/session` now has no imports from the simulator adapters; its scenario import remains for scenario configuration.
- No runtime-failure behavior was changed or inferred.
- Owner must run: `dart format lib test tool`, `flutter analyze --fatal-infos`, `flutter test`.
- Unsure: no compile or runtime validation was performed.
