# Round 5 B-fix 2
- NOT RUN — owner will verify.
- The existing diagnostics test already scans core, diagnostics, and integration using the requested import regex.
- Cell evidence now reports expected profile topology and measured cell count; absent readings are unavailable.
- Added mismatch/absence tests and localized keys in both ARBs and generated l10n files.
- Expected cell count flows from the active adapter profile topology through `DeviceSession`.
- Replaced `_sqrt` with `math.sqrt`; grep found no remaining callers.
- `BmsAdapter` implementers checked: the simulated BMS adapter is the sole implementation.
- Owner must regenerate with `flutter gen-l10n`; no analyzer or tests were run.
- Static compile correctness remains unverified by the owner.
