# Software requirements specification

## Safety and truth

- Every telemetry value is nullable and carries an absence reason. Covered by `domain_test.dart`.
- Physical writes require hardware verification, authorization, range/step/dependency validation, acknowledgement and readback. Covered by `parameter_engine_test.dart`.
- Raw or capture-derived transmission is prohibited. Covered by `protocol_test.dart` and `studio_core_test.dart`.
- Unsupported manufacturers remain research targets. Generated in `CAPABILITY_MATRIX.md`.

## Functional scope delivered

- Responsive Flutter app for Android and Windows with AR/EN, RTL, light/dark and high contrast.
- Deterministic BMS simulator and explicit identification state machine.
- Battery diagnostics, inverter–battery compatibility, parameter pipeline and audit chain.
- Protocol Discovery Studio core and ten-section engineering workspace, disabled by default.
- Contribution redaction, consent, packaging, queue, mock portal, lifecycle gates, trust contracts and feature-gated client flow.
- Shared live `DeviceSession` state with deterministic scenario selection,
  freshness polling, computed link status and persistent connection context.
- Local SQLite diagnostic history and durable configuration backups.
- Simulated parameter edit and backup restoration through the verified write
  pipeline with mandatory readback; mismatch leaves an explicit restore plan.
- Integrity-checked JSON/PDF engineering reports with device, gateway, profile,
  readings, parameters, alarms, findings and session hash. Simulated PDFs carry
  a watermark on every page, and mixed real/simulated reports are rejected.

## Traceability

The automated suite is organized by domain: `domain_test`, `protocol_test`,
`simulator_identification_test`, `diagnostics_test`, `integration_test`,
`parameter_engine_test`, `device_session_test`, `local_database_test`,
`engineering_report_test`, `studio_core_test`, `studio_builder_test`,
`contribution_platform_test`, and `widget_test`.

## Not yet satisfied

Real gateway firmware, real-device profiles, asymmetric production signing,
cloud backend, persistence for the research repository and lifecycle records,
complete production navigation/screens, hardware validation, Android hardware
transport, and production legal approval remain open.
