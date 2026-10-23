# Component catalog

The reusable catalog lives in `lib/design/components.dart`. Components consume
caller-owned data; none of the chart, thermal, link, or hex widgets invents a
measurement.

## Measurements and diagnostics

- `MetricTile`, `RingGauge`, `DeltaBar`: labelled values with semantics and a
  textual or shaped state cue in addition to colour.
- `Sparkline`: plots `List<Measurement>`, normalizes the reported range, and
  breaks the path across absent measurements.
- `TrendChart`: adds minimum/maximum labels to a real measurement series.
- `ThermalMap`: consumes `List<TemperatureReading>`, identifies minimum and
  maximum sensors, and renders absent sensors explicitly.
- `CellGrid`, `CellBarChart`, `CellHeatmap`: ordered battery-cell views.

## Protocol and connection

- `LinkDiagram`: inverter/link/battery nodes with an independent
  healthy/timeout/offline state for each leg.
- `HexGrid`: virtualized `Uint8List` rows with offsets, synchronized ASCII,
  selectable bytes, and labelled field overlays. Technical content is always
  LTR and monospaced.
- `FrameTimeline`, `ConversationLane`, `DiffView`, and `FieldOverlay`: compact
  protocol-research views with explicit data APIs.

## Safety workflows

- `DiffReviewSheet`: before/after rows, validation errors, progress through the
  write steps, loading state, and disabled confirmation when invalid.
- `AuthorizationSheet`: authorization progress and error presentation.
- `ConsentSheet`: explicit acknowledgement before enabling confirmation.
- `AlarmCard`, `SafetyBanner`, `ParameterRow`, and `ProfileCard`: distinct
  safety, parameter, and verification surfaces rather than titled-panel aliases.

## Research, contribution, and reports

- `HypothesisCard`, `RedactionPreview`, `ContributionStatusStepper`,
  `LibraryUpdateCard`, and `ReportPreview` expose purpose-specific state and
  actions.

## Badges

`ModeBadge`, `VerificationBadge`, `SimulatedBadge`, `ConfidenceBadge`,
`RoleBadge`, `SignedBadge`, and `EvidenceChip` pair colour with a symbol, border
shape, label, and semantics. Colour is never the sole status carrier.
