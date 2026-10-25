# ADR 0007: Platform-backed secret storage

## Status

Accepted.

## Context

Persistent audit chains require a per-installation HMAC key. A source constant,
SQLite value, ordinary file, or automatic fallback would let an attacker who
can edit the audit data also forge its integrity marker.

## Decision

Use the `SecretStore` boundary. Production startup supplies
`SecureSecretStore`, backed by `flutter_secure_storage` and the operating
system secure-storage facility. It generates the audit key with
`Random.secure()` on first use and never stores that key in SQLite, source
control, a build-time constant, or an ordinary application file.

The store is initialized before `DeviceSession`. The synchronous `AuditChain`
keeps the loaded key in memory while running; SQLite stores the audit head and
its MAC separately. `InMemorySecretStore` and test secret stores are permitted
only for deterministic tests.

## Failure mode

There is no production fallback. Missing or failed secure storage leaves audit
integrity unavailable, blocks every write, and preserves read-only diagnostics.

## Consequences

Database schema 8 includes `audit_chain_heads.head_mac`. Platform secure-store
coverage still requires owner validation on each supported operating system.
