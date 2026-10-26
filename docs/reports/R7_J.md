# Round 7 — Batch J

- J1: root cause was inconsistent per-screen value/unit formatting. Added the pure-Dart `ValueUnitFormatter` and wired localized precision, digit preference, bidi isolation, localized units, and ICU cycle/frame/sample labels through shared design code and feature screens.
- J1 files: `lib/design/{accessibility,components,precision_ui,value_unit_formatter}.dart`, `lib/features/*.dart`, `lib/app/solardiag_app.dart`, paired EN/AR ARB and generated l10n files.
- J1 scan: checked formatter callers and remaining `toStringAsFixed`; measurement formatting now uses the shared formatter. Differential scoring keeps three decimals because it is not a measurement.
- J2: replaced the dashboard scenario and Studio import-format Material dropdowns with `SolarSelect`. Parameters now switches to the list/detail inspector at 760 px; tablet and desktop expectations are covered.
- J2 files: `lib/features/parameters_screen.dart`, `test/design_system_test.dart`, `test/widget_test.dart`.
- J3: added measurement name/value/unit/freshness semantics and live-region mode/alarm announcements; added primary-reading route checks and announcement coverage.
- J3 files: `lib/design/components.dart`, `test/design_system_test.dart`, `test/widget_test.dart`.
- J4: existing tests already cover min/max/mean retention, telemetry hash-chain verification and tamper detection, mixed simulated/real rejection, and multi-session PDF output; those tests were reviewed, not weakened.
- J5: updated localized value/unit and tablet inspector expectations while retaining assertions. Files: `test/design_system_test.dart`, `test/engineering_report_test.dart`, `test/studio_builder_test.dart`, `test/widget_test.dart`, `lib/reports/engineering_report.dart`.
- J6: compared `assets/icons` with the authoritative §11.4 inventory represented by `design/icons.json`: 76 required, 76 present, no missing or extra symbols.
- Generated localization files were updated for the formatter's current APIs using existing ICU patterns; analyzer verification confirms the generated API and callers agree.
- Static review: grepped formatter calls, dropdowns, measurement precision, plural/unit keys and callers; reviewed imports and ARB key parity. No new dependencies, fake data, or hardware claims were added.
- No golden files were edited. Candidate golden stems for owner review: `home`, battery overview/cells/temperature/faults, parameters, link variants, gateway, Studio, inverter, history, onboarding/settings and Design Lab; review all viewport, theme and locale variants.
- NOT RUN by the implementer. Owner-reported verification: `flutter analyze --fatal-infos` has zero issues; targeted PDF/widget tests pass; the full `flutter test --no-pub --exclude-tags golden` gate passes with 376 tests.
- Residual uncertainty: golden images were not opened or regenerated, and real-device rendering/accessibility remains unvalidated.
