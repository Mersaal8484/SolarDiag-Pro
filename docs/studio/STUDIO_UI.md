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

The UI uses deterministic synthetic studies. Replay Lock is always visible and
capture-derived hardware transmission is prohibited in the domain layer. Draft
profiles remain `studio-draft`, read-only and unloadable in technician mode.

Physical capture, approved profile publication, SLCAN, PCAP/PCAPNG and Vector
ASC ingestion remain unavailable and must not be advertised as implemented.
