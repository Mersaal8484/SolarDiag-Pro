# Round 2 — M2 telemetry, simulator, diagnostics, integration

Date: 2026-10-17

## Completed

- [x] B1: replaced the narrow snapshot boundary with `TelemetrySnapshot`. Pack values, capacities, cycles, per-cell values, labeled temperature sensors, MOSFET/contactor states, balancing mask, CCL/DCL/CVL, raw alarm/protection bits, and link state use `Measurement` with unit, timestamp, quality, and absence reason. Freshness is configurable through `staleAfter`.
- [x] B1: expanded `BmsAdapter` with alarm, parameter, per-cell, capability, health, and pipeline-only parameter-transport access.
- [x] B2: implemented ten seeded deterministic scenarios: healthy, gradual imbalance, high temperature, electrical events, balancing, communication faults, three-module parallel bank, master/slave error, three inverter-peer cases, and parameter write failure/readback mismatch/restart metadata.
- [x] B2: deleted `lib/data/simulated_bms.dart`. Scenarios are selectable in the dashboard and through `dart run tool/simulator_scenarios.dart`.
- [x] B3: added cell standard deviation/persistent outliers, labeled temperature distribution/gradient, profile-driven bilingual fault dictionaries, capacity trend method notes/uncertainty, parallel sharing/SOC/address/role diagnostics, and snapshot differences.
- [x] B4: added aggregate `IntegrationVerdict`, evidence explanation, and non-executable recommendation objects. `LinkScreen` no longer owns demo profile/observation constants; its state is supplied by the workspace. Missing inverter evidence produces `Cannot determine`, never a healthy claim.

## Tests added or changed

- Added `test/m2_completion_test.dart` covering all ten scenarios, scenario ground truth, telemetry completeness, adapter contracts, diagnostics, parallel/master-slave checks, diffs, trends, verdicts, and recommendation data.
- Updated earlier simulator tests to the ten-scenario vocabulary and explicit communication-failure absence reason.
- Updated fault tests to supply a profile dictionary.
- Added a widget test for scenario selection; adjusted the missing-data widget test to scroll past the new scenario control.
- Existing safety, Studio, contribution, integration, localization, accessibility, and widget tests remain enabled.

## Explicit limitations

- The simulator supplies inverter-peer ground truth metadata; the actual `InverterAdapter` and Modbus responder are M3 deliverables.
- The workspace currently has no inverter session, so the Link screen honestly reports unavailable inverter evidence. Live application-wide session streaming is M5.
- The complete telemetry model exists, but dedicated temperature, balancing, health, parallel-bank, history, and report screens are M5 deliverables.
- No physical telemetry, alarms, parameters, or link behavior was validated.

## Verification results

- `dart format --output=none --set-exit-if-changed lib test tool`: 66 files, 0 changed.
- `flutter analyze`: no issues.
- `flutter test --coverage`: 89 passed, 0 failed; 1,933/2,372 lines (81.5%).
- `dart run tool/simulator_scenarios.dart --list`: returned all ten scenario identifiers.
- `flutter build windows --release`: passed.
- `flutter build apk --debug`: passed.
