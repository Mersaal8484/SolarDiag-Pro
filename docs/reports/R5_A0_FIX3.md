# R5 A0 Fix 3

- NOT RUN — owner will verify.
- Root cause: adapter interfaces did not expose simulator clock advancement.
- `SimulationClock.advance()` is synchronous `void`, without parameters; both simulator implementations match.
- Added nullable `simulationClock` accessors to both adapter interfaces and implemented them in both simulator adapters.
- `DeviceSession` advances only through the optional clock interface; no concrete simulator imports or simulator-only session calls remain.
- Grep checked all adapter implementers/fakes and session adapter member usages in `lib/` and `test/`.
- Compile correctness is unverified; owner should run the requested checks.
