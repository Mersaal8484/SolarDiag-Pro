# Round 5 — Batch B (Z2, Z3, Z4)

Status: NOT RUN — owner will verify.

## Z2
- Changed core/diagnostics/simulator models, diagnostics UI, and `test/diagnostics_test.dart`.
- Root cause: diagnostics depended on simulator types, dropped source SOH evidence, and used hard-coded root approximation and fault text.
- Added neutral `ModuleStatus`, preserved SOH evidence, used `dart:math`, and localized fault keys.
- Grep checked `BatteryDiagnostics`, `HealthAssessment`, `FaultDefinition`, and simulator imports; no simulator imports remain in core, diagnostics, or integration.

## Z3
- Changed `device_profiles/profile.schema.json`, `tool/profile_schema_validator.dart`, `tool/profile_check.dart`, and profile schema tests/fixtures.
- Root cause: profile checks did not enforce the requested schema constraints.
- Added a Dart validator for the schema keywords used here and positive/negative fixtures.
- Grep checked validator references and its integration before the existing profile parser.

## Z4
- Changed `lib/session/device_session.dart` and added `test/r5_z4_test.dart`.
- Root cause: compatibility inputs could not be supplied to the session, and absent link counters appeared as zero-valued health.
- Added injectable compatibility profiles/link health and represent unavailable counters as unknown.
- Grep checked session call sites and diagnostic/model references.

## Verification
- No Dart/Flutter commands or tests were run. No tests were weakened or removed.
- Unsure until owner verification: Dart type inference for decoded schema maps and the unexecuted Z4 session tests.
- Owner must run `dart format`, `flutter analyze --fatal-infos`, `flutter test`, `profile_check`, and `reference_check`.
