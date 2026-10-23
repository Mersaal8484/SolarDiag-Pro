# ADR 0004: SVG icon rendering

## Status

Accepted.

## Context

SolarDiag ships a generated SVG icon catalog in `assets/icons/`. The previous
Design Lab substituted Material icons and production screens used `Icons.*`, so
the catalog was not actually rendered and directional mirroring could not be
enforced centrally.

## Decision

Use `flutter_svg` 2.3.x, published by the verified `flutter.dev` publisher, to
render bundled assets through the `SolarIcon` widget. `SolarIcon` applies theme
colour and mirrors only `SolarIconData.directional` assets in RTL.

The dependency performs local asset rendering only. SolarDiag adds no network
access, analytics, or remote icon loading.

## Consequences

- Screens use the generated icon catalog instead of Material icon glyphs.
- SVG rendering is consistent across supported Flutter platforms.
- Icon directionality is tested once at the shared widget boundary.
