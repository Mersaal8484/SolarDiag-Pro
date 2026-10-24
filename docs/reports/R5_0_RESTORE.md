# R5-0 Milestone Report: Restore & Baseline Verification

## 1. Summary
Milestone R5-0 restored all symbols, architecture components, accessibility features, and report pipelines that regressed in commit `818043e`, basing all ongoing work strictly on `main@41822e2` while retaining the verified additions from `818043e` (the X1 test updates, studio streaming analysis files, ADR 0006, and the 300 golden test image artifacts).

---

## 2. Restored Symbols & Components

### `lib/persistence/local_database.dart` (Restored from 555 lines back to full schema)
- `TelemetrySampleRecord`
- `TelemetryRetentionPolicy`
- `saveTelemetrySample` (with downsampling, retention windows, and quality flags)
- `listTelemetrySamples`
- `loadAuditHead`
- `verifyTelemetryChain` (sample SHA-256 hash chaining and tamper detection)
- `schemaVersionForTest`, `rawExecuteForTest`, `openForTest`
- Settings persistence: `setSetting`, `getSetting`, `setBool`, `getBool`

### `lib/session/device_session.dart`
- `samplesFor(String sessionId)`
- `auditHeadFor(String sessionId)`
- `saveTelemetrySample` integration on periodic telemetry ticks with quality assertion flags

### `lib/reports/engineering_report.dart` (Restored from 283 lines back to full pipeline)
- Multi-session reporting support (`EngineeringReportData.sessions`, `eventsBySession`, `samplesBySession`, `auditHeads`)
- Arabic PDF typography and layout handling (`ReportLanguage.arabic`, `ReportLanguage.bilingual`, font loading for `IBMPlexSansArabic`)
- Guard against mixing simulated and physical sessions (`Simulated and real sessions cannot be mixed`)
- Export summary for telemetry sample metrics and audit chain heads

### `lib/design/accessibility.dart` & `lib/design/components.dart`
- `lib/design/accessibility.dart` completely restored:
  - `DigitPreference` (`western`, `arabicIndic`)
  - `DesignPreferences` (`digits`, `workshopMode`, `outdoorHighContrast`, `timeAxisLtr`, `reduceTransparency`)
  - `DesignPreferenceScope`
  - `localizedDigits`, `localizedNumber`
  - `TechnicalText` (LTR enforcement for technical values and monospaced figures)
- `lib/design/components.dart` restored (1824 lines):
  - Semantics annotations (18+ baseline instances preserved)
  - `SolarCard`, `MeasurementCard`, `CellDeltaIndicator`, `ContactorStateIndicator`, `MosfetIndicator`, etc.
  - Full design tokens integration without hardcoded color literals
- Removed transient `lib/design/precision_ui.dart` and `solardiag_r4_fixes.patch`.

### `lib/l10n/*` & Feature Layers
- Confirmed zero loss of ARB keys across `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.
- Restored `settings`, `language`, `themeSetting`, `digitPreference`, `workshopMode`, `outdoorMode`, `pipeline*`, and compatibility verdict strings.
- Restored `SolarIcon` usage and SolarTokens throughout `lib/features/` and `lib/app/`.

### Kept Verified Additions from `818043e`
- `lib/studio/hypothesis.dart`
- `lib/studio/streaming_analysis.dart`
- `lib/studio/validation_runner.dart`
- `test/streaming_analysis_test.dart`
- `test/m3_modbus_profile_inverter_test.dart` (X1 sealed frame unwrap fix & stream tests)
- 300 committed golden screen PNG baselines in `test/golden/core_screens/` and `test/golden/design_lab/`
- `.github/workflows/quality.yml` (`--fatal-infos` verification)
- `docs/adr/0006-studio-file-picker.md` and studio documentation

---

## 3. Full-Suite Verification Evidence

### A. Formatting Check
```powershell
PS D:\SolarDiag Pro> dart format --output=none --set-exit-if-changed lib test tool
Formatted 125 files (0 changed) in 0.83 seconds.
```

### B. Static Analysis (`flutter analyze --fatal-infos`)
```powershell
PS D:\SolarDiag Pro> flutter analyze --fatal-infos
Analyzing SolarDiag Pro...
No issues found! (ran in 3.9s)
```

### C. Profile & Reference Checks
```powershell
PS D:\SolarDiag Pro> dart run tool/profile_check.dart
valid: device_profiles\batteries\_simulated\solardiag_sim.json
valid: device_profiles\inverters\frecon\pv100_pv200.json
valid: device_profiles\inverters\_simulated\solardiag_sim_inverter.json

PS D:\SolarDiag Pro> dart run tool/reference_check.dart --check
Reference registry valid: 6 references.
```

### D. Generator Drift Checks
```powershell
PS D:\SolarDiag Pro> git diff --exit-code docs/CAPABILITY_MATRIX.md
(Clean - exit code 0)

PS D:\SolarDiag Pro> git diff --exit-code lib/design/tokens.g.dart lib/design/solar_icons.g.dart assets/icons
(Clean - exit code 0)
```

### E. Full Test Suite (`flutter test`)
```powershell
PS D:\SolarDiag Pro> flutter test
00:48 +544: All tests passed!
```
Total: **544 passing tests** (including all 300 golden test cases, core domain, persistence, audit chain, and studio tests).

---

## 4. `git diff --stat main..HEAD` Analysis

No files dropped in line count by >20% in `lib/` compared to `main@41822e2`. All core subsystems are intact and verified.
