# Verified parameter engine

All parameter changes pass through `VerifiedWritePipeline`. Validation covers range, step, dependencies, authorization tier, safety acknowledgement, and physical-hardware verification. Simulator writes are explicitly marked and do not confer hardware verification.

The pipeline requires a previously read value, records the attempt, writes once, reads the value back, and compares it exactly. A mismatch triggers one rollback attempt to the known prior value and verifies that rollback. Every state is appended to a SHA-256 chained audit log.

Backups contain schema, profile, device identity, firmware, timestamp, and numeric parameter values. Restore first checks exact identity and firmware and only produces a change plan. Every planned change must then pass through the same write pipeline individually.

The audit hash chain provides tamper evidence, not identity authenticity. Secure storage, signed exports, key management, and durable append-only persistence remain future hardening work.
