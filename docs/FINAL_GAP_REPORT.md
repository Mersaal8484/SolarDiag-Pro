# Honest gap report

## Implemented and tested

Simulator vertical slice, safe nullable telemetry, profile validation,
allow-listed transmission policy, identification state machine, diagnostics,
verified-write workflow with restore planning/audit, compatibility analysis,
responsive AR/EN UI, Studio core/UI and Replay Lock, contribution
privacy/lifecycle/mock portal, library/entitlement contract verification, CI
definition and generated capability matrix.

M5 now includes a shared live session, scenario switching, computed gateway and
link status, adapter-backed parameters, persistent SQLite diagnostic sessions
and configuration backups, verified backup restoration, diagnostic-history UI,
and offline JSON/PDF engineering reports. Stored session evidence is hashed;
report generation verifies it, refuses mixed simulated/real inputs, and marks
simulated output in JSON metadata and on every PDF page.

## Not implemented or not validated

- No ESP32 firmware or physical multi-interface gateway exists in this repository.
- The host-side gateway contract is implemented for passive negotiation, but no USB/BLE/TCP connector or hardware attestation exists.
- No manufacturer profile is verified from authoritative documents or hardware.
- No real battery, inverter, CAN, RS485, RS232, UART or BLE test was run.
- No production backend, reviewer console, KMS/HSM signing, asymmetric trust root, account system or cloud distribution exists.
- SQLite currently persists diagnostic sessions and parameter backups only;
  audit-chain, lifecycle, last-known-good library and Studio research persistence
  still require schema extensions.
- The F2 screen inventory, deep-linkable routing, onboarding and adaptive
  navigation are substantially implemented. Dedicated backup comparison,
  richer history timelines and report-preview polish remain open.
- HMAC signing is mock-only and unsuitable as the production profile trust model.
- No legal approval has been obtained for privacy, contributor terms or reverse-engineering workflows.
- Visual screenshot/golden review has not yet been completed on representative Android devices.
- Windows builds are verified locally; Android build status is reported by the final command results.

## Primary risks

Hardware electrical safety, protocol provenance, firmware-specific behavior, write rollback behavior on real devices, key management, privacy false negatives, localization completeness and UI behavior across the Android device matrix.
