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

## Traceability

The automated suite is organized by domain: `domain_test`, `protocol_test`, `simulator_identification_test`, `diagnostics_test`, `integration_test`, `parameter_engine_test`, `studio_core_test`, `studio_builder_test`, `contribution_platform_test`, and `widget_test`.

## Not yet satisfied

Real gateway firmware, real-device profiles, asymmetric production signing, cloud backend, durable database, generated reports, complete session history, hardware validation, Android hardware transport, and production legal approval remain open.
