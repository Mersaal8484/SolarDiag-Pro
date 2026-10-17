# Round 2 — M1 safety fixes A1–A6

Date: 2026-10-17

## Completed

- [x] A1: removed caller-supplied `simulatedSession`; sealed transports expose immutable `TransportKind`. Simulator construction originates in the simulator library. Existing contribution tests continue to reject synthetic submissions.
- [x] A2: added raw-integer `ParameterCodec`; mismatch/failure performs one write only, marks `Unknown — verify`, and returns a separate `RestorePlan`.
- [x] A3: one serialized pipeline records pre-flight, full snapshot, validation, bilingual diff preview, single-use confirmation, write, readback, verification, and audit. Exact identity, link, authorization expiry, locks, dependencies, cross-parameter constraints, idempotency, tier-3 second token, timeout, and unknown-state gates are present.
- [x] A4: deleted `lib/core/safe_write_pipeline.dart`; an architecture test scans for forbidden `writeParameter(` calls and the duplicate file.
- [x] A5: two independent evidence types are required for passive auto-confirmation; single evidence needs confirmation; exact manual selection is flagged; active queries have timeout, retry, and global limits and use the transport-owned guard. A conditional evidence panel is available to the gateway UI.
- [x] A6: added passive, active-read, and write plans. Active read requires verified capability, explicit start, rate limit, bus-load cap, isolation, and TX interlock. `LoopbackGatewayTransport` proves rejected/passive frames do not reach the wire and backs off on rate, load, and error frames.

## Tests added or changed

- Replaced the duplicate-pipeline domain tests with `test/safety/write_pipeline_test.dart`.
- Updated identification expectations: one passive identifier is no longer confirmation.
- Added raw decimal round-trip, physical-unverified rejection, nine-stage audit, no automatic rollback, explicit restore, token replay/diff binding, expired authorization, unhealthy/unknown state, duplicate idempotency, link loss, serialization, cross-parameter constraints, manual identification, bounded retry, active-read negotiation, transport guard, passive rejection, rate cap, and error back-off tests.
- No acceptance test was weakened to pass.

## Explicit limitations

- The before-state snapshot is integrity-bound into the in-memory audit chain. Durable signed backup persistence depends on the asymmetric trust and persistence work scheduled in M6/A7; no production signing claim is made here.
- No real gateway, isolation, CAN/serial bus, battery, or inverter test was run.
- The evidence panel accepts computed identification state, but the application-wide live session wiring is intentionally scheduled for M5.
- No physical-write capability has been enabled.

## Verification results

- `dart format --output=none --set-exit-if-changed lib test tool`: 65 files, no pending formatting changes after the final pass.
- `flutter analyze`: no issues.
- `flutter test --coverage`: 82 passed, 0 failed; 1,722/2,132 lines (80.8%).
- `flutter build windows --release`: passed.
- `flutter build apk --debug`: passed.
