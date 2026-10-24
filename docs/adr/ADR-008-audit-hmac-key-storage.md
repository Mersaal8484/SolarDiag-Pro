# ADR-008: Platform-backed audit HMAC key storage

## Status

Accepted

## Decision

Persistent audit chains use a per-installation HMAC key supplied by
`SecureSecretStore`, backed by `flutter_secure_storage` and the operating
system's secure storage facility. The key is generated with `Random.secure()`
on first use and is never written to SQLite, the filesystem, source control,
or a build-time constant.

The audit chain remains synchronous while appending entries. Therefore the
secure store is initialized before `DeviceSession` is created and keeps the
key only in memory for the running process. The SQLite audit-head row stores
the head hash and its MAC separately.

## Failure mode

There is no fallback secret store for a persistent session. If secure storage
cannot be initialized, the app shows an audit-integrity warning and
`DeviceSession` locks all write operations. Read-only diagnostics remain
available.

## Consequences

The database schema is version 8 and adds `audit_chain_heads.head_mac`.
Existing databases migrate in place. Test-only `InMemorySecretStore` remains
available only for deterministic test fixtures.
