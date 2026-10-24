# R5 A0 Fix 2

- NOT RUN — owner will verify.
- Root cause: `DeviceSession` uses adapter interfaces that do not expose simulator clock controls.
- Added `SimulationClock` in `lib/core`; both simulated adapters implement its tick and advance API.
- Updated session refresh to advance clocks only when an adapter implements `SimulationClock`; no simulator imports added.
- Static grep checked all `BmsAdapter`/`InverterAdapter` implementers and adapter `.tick`/`.advance()` usages in `lib/` and `test/`.
- `simulator_identification_test` continues to call `advance()` on its concrete simulated adapter.
- Unsure: compile correctness is unverified, as requested.
