# Verified parameter engine

All parameter changes pass through the single `VerifiedWritePipeline`. The transport supplies its immutable physical/simulator kind; callers cannot pass a simulation override. Validation covers exact model and firmware, link state, lock/state, range, raw-domain step, dependencies and cross-parameter constraints, unexpired authorization, safety acknowledgement, and physical-hardware verification.

The pipeline records pre-flight, full snapshot, validation, bilingual diff preview, single-use confirmation, one write attempt, readback, raw-domain verification, and audit outcome. A mismatch or transport failure never triggers an automatic rollback write: device state becomes `Unknown — verify` and a separate restore plan is returned. Restoration is a new, independently confirmed execution.

The pipeline requires a previously read value, records the attempt, writes once, reads the value back, and compares it exactly. A mismatch triggers one rollback attempt to the known prior value and verifies that rollback. Every state is appended to a SHA-256 chained audit log.

Backups contain schema, profile, device identity, firmware, timestamp, and numeric parameter values. Restore first checks exact identity and firmware and only produces a change plan. Every planned change must then pass through the same write pipeline individually.

The audit hash chain provides tamper evidence, not identity authenticity. Secure storage, signed exports, key management, and durable append-only persistence remain future hardening work.
