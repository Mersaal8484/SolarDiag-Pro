# Honest gap report

## Implemented

Simulator vertical slice, safe nullable telemetry, profile validation,
allow-listed transmission policy, identification state machine, diagnostics,
verified-write workflow with restore planning/audit, compatibility analysis,
responsive AR/EN UI, Studio core/UI and Replay Lock, contribution
privacy/lifecycle/mock portal, library/entitlement contract verification, CI
definition and generated capability matrix. Studio remains feature-flagged;
imported sessions and evidence-based findings now save and restore through the
existing SQLite research tables when the application database is supplied.
Library write blocks carry typed causes through the session into the parameters
and library screens, with localized explanations for missing trust, library,
revocation, stale-data and expired-list states. NDA-marked captures remain
eligible for local persistence but are rejected by external capture and
research-bundle export paths.

M5 now includes a shared live session, scenario switching, computed gateway and
link status, adapter-backed parameters, persistent SQLite diagnostic sessions
and configuration backups, verified backup restoration, diagnostic-history UI,
and offline JSON/PDF engineering reports. Stored session evidence is hashed;
report generation verifies it, refuses mixed simulated/real inputs, and marks
simulated output in JSON metadata and on every PDF page.

Post-review corrections (2026-10-21):

- `AuditChain` is now persisted via `DatabaseAuditChainStore` backed by SQLite
  schema migration 6 (`audit_entries` append-only table + `audit_chain_heads`).
  Both tables are protected by SQLite triggers that abort UPDATE and DELETE,
  preventing in-database tampering.
- PDF engineering reports now iterate over all sessions in `data.sessions`,
  matching the JSON export. Single-session and multi-session PDF rendering is
  covered by `engineering_report_test.dart`.
- `restoreParameterBackup` now requires an explicit `safetyAcknowledged`
  parameter; callers must pass the value obtained from user confirmation.
- `linkDiagnostics.expectedMessages` is now derived from the adapter poll
  interval rather than a hard-coded constant.
- `writeLocked` in `applySimulatedParameterChange` is now derived from live
  link state and last-error presence.
- `hasWriteCapability` in `DeviceProfile` now exclusively checks
  `VerificationStatus.verifiedHardware` on write or calibration capabilities,
  removing the unreliable text-matching fallback.
- Open-source research references (`syssi/esphome-jk-bms`, `jblance/mpp-solar`)
  added to `docs/research/references.json` with MIT license tags and legal
  review flags.
- `LEGAL_REVIEW_CHECKLIST.md` created at project root and `docs/studio/`.
- Studio `_FrameTable` replaced `DataTable` with `ListView.separated` + lazy
  `itemBuilder`, enabling virtualized rendering of large captures.
- Studio capture import dialog added with format selector, hex-paste area, and
  NDA acknowledgement toggle.
- Milestone reports created for M5, M6, and M7 in `docs/reports/`.

## Not implemented or not validated

- No ESP32 firmware or physical multi-interface gateway exists in this repository.
- **OPEN DECISION — gateway firmware ownership:** decide whether the ESP32
  firmware belongs in this repository or in a separately governed repository;
  no firmware location, implementation, or validation is implied here.
- The host-side gateway contract is implemented for passive negotiation, but no
  USB/BLE/TCP connector or hardware attestation exists.
- No manufacturer profile is verified from authoritative documents or hardware.
- No real battery, inverter, CAN, RS485, RS232, UART or BLE test was run.
- No production backend, reviewer console, KMS/HSM signing, asymmetric trust
  root, account system or cloud distribution exists.
- SQLite now covers diagnostic sessions, events, backups, settings, lifecycle
  history, and audit chain (schema 8); Studio research session and finding
  persistence uses the existing schema 5 tables. Owner validation of the live
  Studio persistence flow is pending.
- The F2 screen inventory, deep-linkable routing, onboarding and adaptive
  navigation are substantially implemented. Backup comparison, ordered
  state-transition timelines and report preview are implemented; broader
  real-device workflows remain dependent on verified hardware profiles.
- No production signing key or KMS/HSM integration is configured. The shipped
  trust-anchor registry contains placeholder-purpose keys, which are rejected;
  development-purpose keys are rejected in release builds.
- No legal approval has been obtained for privacy, contributor terms or
  reverse-engineering workflows; `LEGAL_REVIEW_CHECKLIST.md` tracks open items.
- Visual screenshot/golden review has not yet been completed on representative
  Android devices. Arabic PDF rendering has not been visually verified on device.
- Build status for the current branch has not been confirmed in this close-out;
  the owner must check the workflow results.

## Round 6 validation status

NOT RUN — owner will verify. This close-out used source searches and Git
history/status only; no Dart/Flutter formatter, generator, analyzer, tests,
builds or CI jobs were run.

## Primary risks

Hardware electrical safety, protocol provenance, firmware-specific behavior, write rollback behavior on real devices, key management, privacy false negatives, localization completeness and UI behavior across the Android device matrix.

## Round 7 Batch J open input

- The supplied Round 7 text references the required icon inventory in §11.4
  but does not include that inventory. The current 76 SVG assets cannot be
  compared authoritatively until the owner supplies the list.
