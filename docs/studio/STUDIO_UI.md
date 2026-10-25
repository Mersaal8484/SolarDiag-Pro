# Protocol Discovery Studio

The feature-flagged engineering workspace contains Sessions, Capture, Frame
Explorer, Analysis, Differential, Hypotheses, Profile Builder, Mapping Editor,
Validation and Export. It is absent by default.

The Studio supports generic capture v2, legacy `.sdcap` v1 migration, tolerant
text import, request/response and polling analysis, checksum candidates, Modbus
classification, structural frame clustering, ranked byte/bit differentials and
evidence-backed findings.
A/B/A repetition strengthens evidence but never auto-confirms a hypothesis.

Research sessions and findings persist in local SQLite schema 5. Shareable
research bundles include capture documents, findings, references and a separate
SHA-256 integrity hash. NDA sessions remain local and are rejected from exports.

The import wizard uses the platform file picker, detects supported formats,
previews metadata and line-numbered malformed input before intake, and records
clock source and accuracy. Supported inputs are `.sdcap`, candump, SLCAN,
Vector ASC, PEAK TRC, mapped CSV and generic hex text. DBC and KCD CAN signal
definitions support deterministic import/export. The exact unsupported list is:
`pcap Modbus TCP`, `pcapng Modbus TCP`, `serial-sniffer binary logs`, and
`serial-monitor vendor exports`.

The monitor uses a fixed-extent virtual list, pause/resume and jump-to-live
controls, a selectable hex/ASCII inspector, byte differences, and correlated
request/response lanes. Replay Lock is always visible and capture-derived or
hypothesis-derived hardware transmission is prohibited in the domain layer.

Analysis has an in-memory path for small interactive sessions and a bounded,
single-pass streaming path for large captures. Validation is offline against
captured frames and mock responses. Drafts remain schema-v2 `studio-draft`,
read-only and unloadable in technician mode. Publication requests are blocked
until `LEGAL_REVIEW_CHECKLIST.md`, offline validation, and authorized physical
hardware validation all pass.
