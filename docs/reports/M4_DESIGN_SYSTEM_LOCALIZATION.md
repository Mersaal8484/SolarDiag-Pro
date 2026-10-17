# M4 — Design system and localization

Completed on 2026-10-17.

## Delivered

- A token-driven Flutter theme generated from `design/tokens.json`.
- A generated, repository-owned SVG icon inventory with more than 70 symbols
  and explicit directional metadata.
- Reusable accessible components for metrics, gauges, connection state,
  evidence, warnings, and technical text.
- Bundled Inter, IBM Plex Arabic, and JetBrains Mono fonts with their license
  notices.
- English and Arabic ARB localization across all feature screens, including
  RTL-aware navigation and locale-sensitive controls.
- Removal of the temporary `AppStrings`/`pick` compatibility layer.
- Design documentation covering principles, typography, tokens, motion,
  accessibility, icons, and the component catalog.
- CI generation checks for localization, tokens, and icons.
- Architecture tests that reject feature-level direct colors, literal user
  interface text, legacy localization calls, and the disallowed inverter term.

## Evidence

- `flutter gen-l10n`: completed successfully using `l10n.yaml`.
- `dart format lib test tool`: 87 files checked; four files formatted.
- `flutter analyze`: no issues found.
- `flutter test`: all 106 tests passed.

## Notes

- Package update notices are informational; current dependency constraints
  resolve successfully.
- Hardware behavior and physical-write safety remain unchanged by this user
  interface milestone.
