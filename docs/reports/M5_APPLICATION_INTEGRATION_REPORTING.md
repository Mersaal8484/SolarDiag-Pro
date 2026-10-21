# M5 — Application integration, persistence, and reporting

## Delivered

- **Shared Live Session (`DeviceSession`):**
  - Manages active BMS and inverter simulator telemetry, freshness polling, dynamic link health derivation, alarms, and connection state.
  - Exposes deterministic scenario selection across all 10 simulator test scenarios.
  - Provides link diagnostics computing delivery ratios and SOC consistency without static assumptions.
  - Gated write context deriving `writeLocked` directly from link health and error status.

- **Verified Write Pipeline and Parameter Restore:**
  - Integrated with `VerifiedWritePipeline` across pre-flight, snapshot, validation, bilingual diff preview, single-use confirmation token, write, readback, verification, and audit.
  - Parameter backup creation with schema v1 serialization.
  - Backup restoration with required explicit `safetyAcknowledged` parameter and user confirmation.
  - Separate restore plan and error handling on readback mismatch.

- **Local SQLite Persistence (`LocalDatabase`):**
  - Schema migrations 1 through 6 with `PRAGMA foreign_keys = ON` and strict SQLite typing.
  - Durable storage of diagnostic sessions with SHA-256 integrity hash.
  - Append-only diagnostic state-transition events timeline (`diagnostic_events`).
  - Durable parameter backups storage with descending timestamp index.
  - Local application settings table for first-run onboarding completion and user preferences.
  - Append-only immutable `audit_entries` and `audit_chain_heads` for audit chain persistence (migration 6).
  - Integration with `DatabaseAuditChainStore` in `DeviceSession`.

- **Engineering Reports Service (`EngineeringReportService`):**
  - Offline JSON export with comprehensive device, gateway, profile, multi-session telemetry, alarms, parameters, and findings.
  - Offline PDF generation with A4 pagination, Arabic (`IBMPlexSansArabic`) and English font embedding, and watermark banners on simulated sessions.
  - PDF multi-session iteration rendering all diagnostic sessions matching the JSON schema.
  - SHA-256 session integrity check preventing report generation on corrupted data.
  - Fail-closed validation rejecting mixed simulated and physical sessions.

- **Navigation & Workspace Shell:**
  - Responsive adaptive layout (`WorkspaceShell`) supporting mobile navigation bar and desktop rail.
  - Onboarding workflow, parameter comparison dialogs, and ordered diagnostic timelines.

## Verification & Traceability

- Automated suite coverage:
  - `device_session_test.dart`: session lifecycle, scenario switching, parameter read/write/restore, readback mismatch.
  - `local_database_test.dart`: SQLite CRUD, integrity hashing, schema migrations 1-6, append-only triggers.
  - `engineering_report_test.dart`: JSON/PDF generation, multi-session export, hash validation, watermark checks.
  - `parameter_backup_comparison_test.dart`: backup diff analysis and restore planning.

## Limitations & External Boundaries

- Physical multi-interface gateway hardware (ESP32/STM32) and USB/BLE transport connectors remain future integration milestones.
- Write operations remain constrained to the deterministic simulator with readback verification.
