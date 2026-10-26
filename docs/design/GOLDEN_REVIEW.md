# Golden visual review

## Test environment

- Comparison platform: Windows, CI job `goldens`, Flutter test rasterizer,
  device pixel ratio 1.0. Golden tests use the `golden` tag and do not run in
  the Linux `flutter` job.
- Bundled fonts: Inter, IBM Plex Sans Arabic, and JetBrains Mono.
- Viewports: 390×844, 834×1194, and 1440×900.
- Variants: light/dark and English/Arabic RTL. Design Lab also covers 100% and
  200% text scale. Motion is disabled for deterministic reduced-motion output.

## Review status

The T4 harness defines 300 images: 24 Design Lab variants and 276 core-screen
variants. Newly defined baselines must be regenerated before visual review. Rows
remain **pending visual review** until the PNG files are opened and inspected;
an automated golden pass alone is not recorded as human visual approval.

Regenerate on Windows with `flutter test --tags golden --update-goldens`.
Open and review every regenerated PNG before committing it.

| Golden group | Coverage | Review result | Defects/fix |
|---|---|---|---|
| Design Lab | 3 viewports × 2 themes × 2 locales × 2 text scales | Pending visual review | `CellTile` responsive layout changed; regenerate and review |
| Home | 3 × 2 × 2 | Pending visual review | Connection capsule wraps/ellipsizes; regenerate and review |
| Battery overview | 3 × 2 × 2 | Pending visual review | Battery card width and cycle precision changed; regenerate and review |
| Cell monitoring | grid/bars/heatmap × 3 × 2 × 2; imbalance evidence | Pending visual review | Cell layout and battery card width changed; regenerate and review |
| Temperature | 3 × 2 × 2; high-temperature evidence | Pending visual review | Pending |
| Fault diagnostics | 3 × 2 × 2; electrical alarms | Pending visual review | Pending |
| Service functions | 3 × 2 × 2 | Pending visual review | Pending |
| Report preview | 3 × 2 × 2 | Pending visual review | Pending |
| Parameters | view/diff/progress/failure × 3 × 2 × 2 | Pending visual review | Pending |
| Link | compatible/limits/incompatible/unknown × 3 × 2 × 2 | Pending visual review | Pending |
| Gateway | 3 × 2 × 2 | Pending visual review | Integer frame counters changed; regenerate and review |
| Studio | 3 × 2 × 2 | Pending visual review | Localized integer counts and persisted session list changed; regenerate and review |
| Settings | 3 × 2 × 2 | Pending visual review | Pending |
| Inverter diagnostics | 3 × 2 × 2 | Pending visual review | Pending |
| Diagnostic history | 3 × 2 × 2 | Pending visual review | Pending |
| Onboarding | 3 × 2 × 2 | Pending visual review | Pending |

## Inspection checklist

For every generated image inspect clipping, overflow, alignment, contrast,
Arabic shaping, RTL ordering and directional icon mirroring, technical LTR
values, 200% text resilience, and whether status remains understandable without
colour. Record each observed defect and its fixing commit in the table above,
then regenerate and re-review the affected group.
