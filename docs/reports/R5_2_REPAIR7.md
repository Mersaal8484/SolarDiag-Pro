# R5-2 Repair 7

- Status: NOT RUN — no Flutter/Dart tools or checks were run.
- N1: Renamed `createConfirmationToken` to `mintShownPlanConfirmation`; updated every call in `lib/` and `test/`. The factory remains the only production constructor caller.
- Static search confirms no `ConfirmationToken(` pattern in `lib/` outside `parameter_models.dart` and `confirmation_factory.dart`.
- N2: Corrected Y4 access strings to `read_only` and `read_write`; verified remaining capability statuses match `VerificationStatus` names.
- The Y4 fixture supplies every field read by `DeviceProfile.fromJson`, including provenance, allowed frames/ranges, telemetry, topology, vectors, and checklist.
- Owner must run: `dart format lib test tool`; `flutter analyze --fatal-infos`; `flutter test`.
- Compile correctness and test results remain unverified by design.
