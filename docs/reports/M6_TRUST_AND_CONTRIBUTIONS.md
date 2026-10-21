# M6 — Trust, profile integrity, and contribution platform

## Delivered

- **Cryptographic Trust Foundation (`profile_integrity.dart`):**
  - Ed25519 signature verification via `Ed25519TrustVerifier`.
  - Canonical JSON normalization and SHA-256 hash checking.
  - Constant-time string and byte equality checks preventing timing side-channel leaks.

- **Signed Profile & Library Sync (`signed_tokens.dart` & `profile_registry.dart`):**
  - `LibraryPack` serialization with minimum application version gating, expiration, and individual profile hash verification.
  - Strict anti-rollback protection rejecting library packs with version <= installed pack version.
  - Revocation list enforcement supporting pack-level and profile-level revocation.
  - Offline restoration from durable last-known-good library pack storage.
  - Strict `hasWriteCapability` qualification requiring `VerificationStatus.verifiedHardware` on write or calibration capabilities, eliminating arbitrary text-matching heuristics.
  - Physical profile validation prohibiting simulated capability claims in physical profiles.

- **Contribution Privacy, Redaction, and Lifecycle:**
  - Automated redaction of sensitive device serials, MAC addresses, technician identifiers, and proprietary register offsets.
  - Two-stage explicit consent recording with immutable cryptographic proof.
  - Multi-stage contribution review state machine (`ContributionStage`) with role-based access gates.
  - Append-only lifecycle review history in SQLite schema 4 with tamper-evident SQLite triggers.
  - Offline queue for contribution packages with payload integrity verification.
  - Mock contribution portal validating end-to-end contribution workflow.

- **Research Reference Registry:**
  - Registered authoritative machine-readable references in `docs/research/references.json`.
  - Added open-source community research leads (`syssi/esphome-jk-bms` and `jblance/mpp-solar`) with explicit MIT license tags, research-only obligations, and legal review flags.
  - Automated synchronization with `THIRD_PARTY_NOTICES.md` via `tool/reference_check.dart`.

## Verification & Traceability

- Automated suite coverage:
  - `audit_chain_test.dart`: hash chaining, tampering detection, export/import.
  - `contribution_platform_test.dart`: consent, redaction, queue, lifecycle state gates, mock portal.
  - `local_database_test.dart`: contribution lifecycle table append-only triggers.
  - `reference_check.dart`: reference schema validation, profile provenance checks, third-party notice generation.

## Limitations & External Boundaries

- Production KMS / HSM asymmetric private key signing infrastructure remains hosted external to this client repository.
- Community profiles remain quarantined as read-only research targets until manufacturer validation.
