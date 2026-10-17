# Honest gap report

## Implemented and tested

Simulator vertical slice, safe nullable telemetry, profile validation, allow-listed transmission policy, identification state machine, diagnostics, verified-write workflow with rollback/audit, compatibility analysis, responsive AR/EN UI, Studio core/UI and Replay Lock, contribution privacy/lifecycle/mock portal, library/entitlement contract verification, CI definition and generated capability matrix.

## Not implemented or not validated

- No ESP32 firmware or physical multi-interface gateway exists in this repository.
- No manufacturer profile is verified from authoritative documents or hardware.
- No real battery, inverter, CAN, RS485, RS232, UART or BLE test was run.
- No production backend, reviewer console, KMS/HSM signing, asymmetric trust root, account system or cloud distribution exists.
- HMAC signing is mock-only and unsuitable as the production profile trust model.
- No legal approval has been obtained for privacy, contributor terms or reverse-engineering workflows.
- Visual screenshot/golden review has not yet been completed on representative Android devices.
- Windows builds are verified locally; Android build status is reported by the final command results.

## Primary risks

Hardware electrical safety, protocol provenance, firmware-specific behavior, write rollback behavior on real devices, key management, privacy false negatives, localization completeness and UI behavior across the Android device matrix.
