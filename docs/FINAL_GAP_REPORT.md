# SolarDiag Pro — honest final gap report

This report maps the implemented source to the master specification. A status
of **implemented** means the software path and automated checks exist; it does
not mean that real hardware, legal, visual, signing, or production deployment
validation has occurred.

## Specification closure matrix

| Specification area | Status | Source evidence | Automated evidence |
|---|---|---|---|
| Safety, authorization, audit and trust | Implemented in software; physical validation and production keys remain open | `lib/safety/`, `lib/auth/`, `lib/audit/`, `lib/trust/` | `test/t1_safety_and_trust_test.dart`, `test/r5_2_trust_and_safety_test.dart`, `test/safety/write_pipeline_test.dart`, `test/audit_chain_test.dart` |
| Protocol correctness and Modbus | Implemented for the declared passive/read and guarded-write contracts | `lib/protocols/modbus/`, `lib/transport/`, `lib/integration/` | `test/t2_correctness_test.dart`, `test/r5_modbus_client_test.dart`, `test/m3_modbus_profile_inverter_test.dart`, `test/protocol_test.dart` |
| Profiles, simulator and identification | Implemented for schema-checked profiles and explicitly simulated adapters; manufacturer validation remains open | `lib/protocol/`, `lib/simulator/`, `device_profiles/` | `test/profile_schema_test.dart`, `test/simulator_identification_test.dart`, `test/m2_completion_test.dart` |
| Live session, diagnostics and persistence | Implemented with nullable telemetry, SQLite sessions/events/backups/settings and append-only audit storage | `lib/session/`, `lib/diagnostics/`, `lib/persistence/local_database.dart` | `test/device_session_test.dart`, `test/diagnostics_test.dart`, `test/local_database_test.dart`, `test/parameter_backup_comparison_test.dart` |
| Verified parameter writes and restoration | Implemented behind identity, authorization, readback and audit gates; real-device rollback is not validated | `lib/parameters/`, `lib/safety/` | `test/safety/write_pipeline_test.dart`, `test/t1_safety_and_trust_test.dart`, `test/r5_z4_test.dart` |
| Engineering reports | Implemented for integrity-checked JSON/PDF with simulation marking and mixed-source refusal | `lib/reports/engineering_report.dart`, `lib/features/session_history_screen.dart` | `test/engineering_report_test.dart` |
| Arabic/English UI, accessibility and adaptive design | Implemented in source; current PNGs remain pending human visual review | `lib/design/`, `lib/features/`, `lib/l10n/` | `test/design_system_test.dart`, `test/ui_polish_test.dart`, `test/widget_test.dart`, golden suites |
| Protocol Discovery Studio | Implemented as feature-flagged, read-only research tooling with import, analysis, inference, persistence and Replay Lock | `lib/studio/`, `lib/features/studio_workspace.dart` | capture, inference, protocol, differential, streaming, builder, persistence and Studio end-to-end tests |
| Contribution platform | Local consent, redaction, lifecycle, queue, reward and mock portal implemented; production service and legal approval remain open | `lib/contribution/`, `docs/contribution_platform/` | `test/contribution_platform_test.dart`, `test/r7_h_contribution_platform_test.dart` |
| Gateway contract and capability evidence | Host-side negotiation/guard contracts and generated capability evidence implemented; gateway firmware and physical connectors are absent | `lib/gateway/`, `docs/CAPABILITY_MATRIX.md`, `tool/generate_capability_matrix.dart` | `test/gateway_contract_test.dart`, profile/reference check tools |
| Release gates | CI definition includes format/generator drift, localization, schema/reference checks, fatal analyzer, non-golden tests, APK build and a separate Windows golden job | `.github/workflows/quality.yml` | GitHub Actions execution is owner/CI evidence, not an implementer-run claim |

## Implemented behavior worth calling out

- Writes cannot bypass the verified pipeline; authorization material is issued
  outside `DeviceSession`, and audit records persist through an HMAC-protected,
  append-only chain.
- Library and revocation failures carry typed, localized write-block reasons.
- Studio research sessions/findings persist locally; NDA-marked material is
  rejected by external export paths.
- Report identity is now explicit. Production code no longer supplies a fake
  simulator device/profile/gateway identity when evidence is absent; an unknown
  gateway is rendered as “Not reported / غير مبلغ عنه”.
- Report generation verifies stored evidence, rejects mixed simulated/real
  inputs, and marks simulated output in metadata and every PDF page.

## Batch K static audit

- `Healthy|ENFORCED|Verified|Online|Connected` matches in feature/design source
  are dynamic session states, Design Lab examples, enum/icon identifiers, or
  localized labels—not fixed measurements presented as live evidence.
- Hard-coded device/profile IDs are confined to `lib/simulator`, simulator-ID
  validation guards, and localized text explicitly labelled “Simulator only”.
  The previous report-model simulator defaults were removed.
- Remaining raw enum names are technical/developer labels: simulator scenario
  selection, temperature-sensor kind, diagnostic confidence, Studio source,
  finding state and mapping data type. They are listed rather than represented
  as localized verdicts; localization is still incomplete for those labels.
- No task-comment marker was found in implementation source. `placeholder`
  matches are intentional fail-closed trust-anchor purpose values, redaction
  field names, tests, and the honestly labelled undeployed contribution API.

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
- SQLite covers diagnostic sessions, events, backups, settings, lifecycle,
  Studio research data and audit chain. Owner validation of the live Studio
  persistence flow on every target platform is still pending.
- No production signing key or KMS/HSM integration is configured. Shipped
  placeholder-purpose trust anchors fail closed; development anchors are
  rejected in release builds.
- Secure-storage behavior has automated abstraction coverage, but Android and
  other target-platform keystore behavior has not been validated here.
- No legal approval has been obtained for privacy, contributor terms,
  reverse-engineering workflows, or market-specific requirements;
  `LEGAL_REVIEW_CHECKLIST.md` tracks open items.
- Visual screenshot/golden review has not been completed. Arabic PDF rendering
  has not been visually verified on representative devices.
- Real-device write rollback, electrical safety, firmware-specific behavior,
  protocol provenance and the Android device matrix remain residual risks.

## Validation status

The owner reported `flutter analyze --fatal-infos` with no issues and the full
non-golden suite with **376 tests passed** after Batch J. Batch K changes are
**NOT RUN — owner will verify**. The implementer did not run Dart/Flutter,
generators, tests, builds, goldens, or CI, and did not open any PNG.

## Golden status

Every group remains pending in `docs/design/GOLDEN_REVIEW.md`. The required
Windows update command is `flutter test --tags golden --update-goldens`; the
owner or reviewer must then open every PNG and record defects.
