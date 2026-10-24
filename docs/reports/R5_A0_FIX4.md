# R5 A0 Fix 4

- NOT RUN — owner will verify.
- S1 trigger: `await rootBundle.loadString('device_profiles/batteries/_simulated/solardiag_sim.json')`; replaced it with embedded simulator profile JSON.
- Kept `loadBundledSimulator()` and its bundled-profile validation behavior; the loader no longer needs Flutter bindings.
- S2 failing expression: `await firstSync.apply(pack, now: now, revocations: revocations)`; the fixture revoked the pack before initial installation, which `apply` correctly rejects.
- Fixed the fixture chronology: apply with sequence 1, then persist pack/profile revocations with sequence 2 and verify restart restoration.
- Grep checked every `loadBundledSimulator()` caller and bundle access in protocol, simulator, and session code.
- No compile or runtime checks were run.
