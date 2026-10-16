# SolarDiag Pro design system

The visual direction is a calm engineering laboratory: deep green communicates the instrument surface, acid lime is reserved for explicit states such as simulation, and neutral panels keep dense diagnostic data legible.

## Foundations

- `SolarTokens` is the semantic theme extension; widgets consume semantic states instead of private colors.
- Measurements use tabular numerals to prevent layout jitter.
- The app supports English/LTR and Arabic/RTL at runtime.
- Light, dark, and high-contrast variants are generated from the same tokens.
- Missing device data is textual and never substituted with zero.
- Design Lab is the living component and state reference inside the app.

Motion remains limited to platform navigation and theme transitions. A persistent reduce-motion preference will be added with the settings store.
