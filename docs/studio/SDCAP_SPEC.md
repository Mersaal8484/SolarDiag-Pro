# `.sdcap` capture format

Version 1 is a UTF-8 JSON container with magic `SOLARDIAG_CAPTURE`, schema version, payload, and SHA-256 integrity hash. The payload contains session identity, interface, source, UTC start time, synthetic flag, notes, and timestamped frames.

Implemented sources: synthetic sessions and programmatic passive-gateway sessions. The model can represent candump/CSV imports, but text importers are not implemented yet and must not be advertised as supported.

Exports reject sessions marked as containing NDA material. Integrity detects accidental or malicious modification but is not a digital signature.
