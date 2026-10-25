# T3 — Application truthfulness report

**Commit reviewed:** `41822e2` plus persistence/report corrections.
**Validation now:** NOT RUN — owner will verify.

- A1: gateway mode, counters, load, negotiation, and last decision are derived
  from session contract state; the static claim scan exists.
- A2: SQLite stores telemetry samples and ordered diagnostic events, includes
  sample integrity links, and exposes retention/downsampling logic. Runtime
  retention behavior still needs owner verification on the current branch.
- A3: JSON/PDF reports iterate sessions, reject simulated/real mixing, verify
  stored evidence, include summaries/findings/audit data, and watermark
  simulated output. Arabic PDF visual review remains pending.
- A4: literal status-claim and raw-verdict scans exist; real hardware truth
  remains unavailable because this repository has no physical connector.

The deterministic simulator is always labelled simulated. No constant value
in this report is claimed as a real measurement. Relevant owner checks are
`test/t3_truthfulness_test.dart`, `test/local_database_test.dart`, and
`test/engineering_report_test.dart`.
