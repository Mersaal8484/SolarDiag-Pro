# T2 — Correctness report

**Commit reviewed:** `41822e2` plus later R5/R6 corrections.
**Validation now:** NOT RUN — owner will verify.

- C1: exception responses are typed and consumed; CRC/PDU/address checks exist.
  The passive stream decoder still uses heuristic window scanning, so the
  requested pending-request length-aware decoder remains incomplete.
- C2: guarded RTU/TCP `ModbusClient`, partial-read links, timeouts, exception
  handling, and value-bound single-use write authorization exist. Round 7 F
  makes write preflight private and requires an explicit register kind.
- C3: nullable SOH, neutral `ModuleStatus`, keyed faults, `dart:math`, and
  missing-cell evidence are implemented in diagnostics tests.
- C4: evidence quality and margin downgrades are implemented. Simulator peer
  compatibility is present, but real inverter evidence is not validated.
- C5: missing link counters default to zero/unknown instead of fabricated
  failures; only simulated/contract counters have been exercised.
- C6: the simulated inverter profile, schema subset validation, shared CRC,
  units, and safe reference parsing exist.

No physical Modbus device, serial timing, or manufacturer profile was
validated. The tests named in `test/t2_correctness_test.dart`,
`test/r5_modbus_client_test.dart`, and
`test/m3_modbus_profile_inverter_test.dart` require owner execution.
