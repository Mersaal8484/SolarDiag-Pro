# Round 7 — Batch J

- J1: root cause was inconsistent per-screen value/unit formatting. Added the pure-Dart `ValueUnitFormatter` and wired localized precision, digit preference, bidi isolation, localized units, and ICU cycle/frame/sample labels through shared design code and feature screens.
- J1 files: `lib/design/{accessibility,components,precision_ui,value_unit_formatter}.dart`, `lib/features/*.dart`, `lib/app/solardiag_app.dart`, paired EN/AR ARB and generated l10n files.
- J1 scan: checked formatter callers and remaining `toStringAsFixed`; measurement formatting now uses the shared formatter. Differential scoring keeps three decimals because it is not a measurement.
- J2: no Material dropdown widgets were found in feature code, so none needed replacing. Parameters' list/detail inspector breakpoint was too wide; it now activates at 760 px. Tablet and desktop expectations are covered.
- J2 files: `lib/features/parameters_screen.dart`, `test/design_system_test.dart`, `test/widget_test.dart`.
- J3: added measurement name/value/unit/freshness semantics and live-region mode/alarm announcements; added primary-reading route checks and announcement coverage.
- J3 files: `lib/design/components.dart`, `test/design_system_test.dart`, `test/widget_test.dart`.
- J4: existing tests already cover min/max/mean retention, telemetry hash-chain verification and tamper detection, mixed simulated/real rejection, and multi-session PDF output; those tests were reviewed, not weakened.
- J5: updated localized value/unit and tablet inspector expectations while retaining assertions. Files: `test/design_system_test.dart`, `test/engineering_report_test.dart`, `test/studio_builder_test.dart`, `test/widget_test.dart`, `lib/reports/engineering_report.dart`.
- J6: 76 SVG assets exist, but the authoritative §11.4 required-icon inventory was absent from the supplied spec, so completeness could not be assessed without inventing requirements. `docs/FINAL_GAP_REPORT.md` records this limitation.
- Generated localization files were updated for the formatter's current APIs using existing ICU patterns; owner must run `flutter gen-l10n` to verify exact generated output.
- Static review: grepped formatter calls, dropdowns, measurement precision, plural/unit keys and callers; reviewed imports and ARB key parity. No new dependencies, fake data, or hardware claims were added.
- No golden files were edited. Candidate golden stems for owner review: `home`, battery overview/cells/temperature/faults, parameters, link variants, gateway, Studio, inverter, history, onboarding/settings and Design Lab; review all viewport, theme and locale variants.
- NOT RUN — owner will verify. No Dart/Flutter commands, formatter, generator, tests, analyzer, build or CI were run.
- Compile uncertainty remains for generated localization output and widget semantics/layout until owner verification.
