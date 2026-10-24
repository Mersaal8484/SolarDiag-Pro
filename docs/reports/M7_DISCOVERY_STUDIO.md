# M7 — Protocol Discovery Studio

## Delivered

- **Core Analysis & Reverse-Engineering Engine:**
  - Multi-format ingestion via `CaptureImporterRegistry`:
    - SolarDiag `.sdcap` format (v1 and v2) with streaming codec.
    - Linux SocketCAN `candump` format (compact and spaced log formats).
    - User-mapped CSV capture format with auto-detection assistant (`CsvMappingAssistant`).
    - Generic HEX text capture format with configurable delimiter and column mappings.
    - SLCAN `t`/`T`/`r`/`R` import with optional timestamps and malformed-line reporting.
    - Explicit non-support classification for PCAP/PCAPNG and Vector ASC.
  - Signal analysis: identifier cadence, cycle timing, payload length distributions, changing bit/byte entropy.
  - Request/response pairing, periodic polling detection, and Modbus frame detection.
  - Safe differential analysis (`SafeDifferentialAnalyzer`) computing ranked candidate fields across A/B and repeated A/B/A test captures without auto-confirming hypotheses.
  - Protocol findings and evidence binding (`findings.dart`) linking observations directly to captured frame intervals.

- **Profile Draft Builder & Validation:**
  - `ProfileBuilder` assembling `StudioProfileDraft` models with field mappings, scaling, units, and evidence links.
  - Offline validation runner covering captured replay, mock responses, generated parser assertions, captured Modbus CRC, and identity matching without bus interaction.
  - Studio export service outputting quarantined read-only draft profiles.
  - Read-only draft isolation: schema-v2 drafts carry `status: "studio-draft"` and are rejected by production technician loading routines.

- **Discovery Studio Workspace UI:**
  - Ten-section engineering workspace: Sessions, Capture, Frame Explorer, Analysis, Differential, Hypotheses, Profile Builder, Mapping Editor, Validation, and Export.
  - Replay Lock badge permanently visible across all Studio views.
  - Virtualized frame explorer (`_FrameTable`) with fixed-extent scrolling and lazy row instantiation supporting large captures.
  - Platform file-picker import wizard with detection, preview, line-numbered issues, clock metadata, NDA/synthetic flags, and live session updates.
  - Pause/resume and jump-to-live monitor controls, synchronized hex/ASCII inspection, byte diff, and request/response lanes.
  - Bounded single-pass analysis for boundary, checksum, correlation, and clustering work on million-frame streams.

- **Legal, Ethics, and Governance Boundaries:**
  - Documented legal and ethical boundary policies in `docs/studio/LEGAL_AND_ETHICS.md`.
  - Pre-publication compliance checklist in `docs/studio/LEGAL_REVIEW_CHECKLIST.md`, enforced by a fail-closed Studio release gate.
  - Permanent Replay Lock: captures can never be replayed or used to transmit physical frames.
  - Default feature flag isolation: Studio is disabled by default in production builds.

## Verification & Traceability

- Automated suite coverage:
  - `studio_core_test.dart`: capture models, analysis engine, findings, draft profile building.
  - `capture_importers_test.dart`: candump, SLCAN, sdcap, CSV, and generic hex importers with corrupted/edge-case inputs.
  - `streaming_analysis_test.dart`: one-million-frame bounded-memory and elapsed-time budget.
  - `differential_analysis_test.dart`: A/B and A/B/A differential candidates and entropy ranking.
  - `protocol_analysis_test.dart`: request-response pairs, polling cycles, Modbus detection.
  - `studio_builder_test.dart`: validation rules, export format, draft isolation.
  - `studio_end_to_end_test.dart`: import through analysis, diff, non-transmittable hypothesis, schema-v2 draft, offline validation, export, release gate, and technician rejection.

## Limitations & External Boundaries

- Hardware-dependent live passive gateway capture and SLCAN serial adapter control require physical gateway firmware; SLCAN file import is implemented.
- Million-frame load test benchmarks remain validated via streaming unit tests; real-time physical streaming requires hardware.
