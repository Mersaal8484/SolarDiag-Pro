# Round 7 - Batch I

- I1 files: `gateway_contract.dart`, `bms_adapter.dart`, simulator adapters,
  `gateway_contract_test.dart`, and `GATEWAY_HARDWARE.md`.
- Decision: announcements declare interfaces and four standard CAN rates;
  custom rates work only when explicitly declared as validated.
- Listen-only remains the passive default; active plans retain frame-rate and
  bus-load caps. Existing runtime transport still audits back-off/rejection.
- CAN identifiers and RS485 unit/function pairs now share a contract decision;
  misses are dropped and labelled `tx_allowlist_drop` for audit recording.
- `LinkHealth` adds nullable CAN TEC, REC, and bus-off evidence. Simulators
  explicitly emit synthetic counters; unavailable real evidence stays null.
- High-voltage active reads require verified-hardware evidence; passive
  monitoring remains available. No firmware or hardware claim was added.
- I2 files: registry, device library, generator, and contract tests.
- Decision: 6 inverter and 9 battery entries are metadata-only research targets;
  no profile, capability, parameter, command, or register map was invented.
- I3: owner regenerated `CAPABILITY_MATRIX.md`; it now derives all 15 research
  targets from the shared registry without claiming device capabilities.
- Firmware ownership is an open decision in `FINAL_GAP_REPORT.md`.
- Signature review: new fields are optional or have defaults; 4 `LinkHealth`
  call sites and all gateway descriptor constructors were inspected.
- Fixtures match `GatewayDescriptor.fromJson`; no schema or ARB key changed.
- Architecture scan: no firmware, private key, write bypass, or manufacturer
  protocol details were added. ARB EN/AR parity is unchanged.
- Owner verification: `analyze --fatal-infos` passed; gateway 16/16, T1 26/26,
  and Z4 7/7 passed; profile check validated all 3 installed profiles.
- Broader UI/design runs exposed five redesign-compatibility failures (theme,
  lazy/off-screen content, overflow, icons/colors); retained for Batch J/J5.
- Uncertainty: physical hardware is unproved. NOT RUN by Codex; owner verified.
