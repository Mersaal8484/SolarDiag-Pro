# ADR 0003: Local SQLite persistence

## Status

Accepted on 2026-10-18 for M5.

The engineering report exporter uses `pdf` 3.13.1 (Apache-2.0). It is a
pure-Dart, cross-platform PDF producer with TrueType font support, which lets
the app generate Arabic/English reports offline without a print-service or
network dependency. `path_provider` supplies the user application-documents
directory for JSON and PDF exports.

## Context

SolarDiag Pro must persist diagnostic sessions, parameter backups, audit-chain
records, lifecycle history, last-known-good profile packs, and research data on
Android and Windows. The records are relational, require transactions, and must
remain usable offline. A collection of independent JSON files would make atomic
updates, indexing, migrations, and integrity checks unnecessarily fragile.

## Decision

Use `sqlite3` 3.5.2 as the local database engine and `path_provider` 2.1.6 to
locate the platform application-support directory. The database layer owns the
schema, migrations, parameterized statements, and transactions. Tests use an
in-memory SQLite database.

We selected direct SQLite access instead of Drift for this milestone because
the required queries are small and explicit, and direct access avoids a code
generator and generated model layer. Repository interfaces keep the storage
implementation replaceable. Database work must not run in rendering code; if
profiling shows measurable latency, the same repository will move its native
connection to a background isolate.

## Licensing and maintenance

- `sqlite3` is MIT licensed, actively maintained by the Drift/SQLite Dart
  maintainer, supports Android and Windows, and bundles SQLite through Dart
  native build hooks. Version 3.5.2 is pinned because Flutter 3.44.1 pins
  `meta` 1.18.0; sqlite3 3.6.0 and newer currently require `meta` 1.19.0
  through `record_use` and cannot resolve with this Flutter SDK.
- `path_provider` is BSD-3-Clause licensed and maintained by the Flutter team.
- Neither dependency changes the safety boundary or enables device writes.

## Consequences

- Native builds include SQLite and a platform path-provider implementation.
- Schema changes require numbered migrations and migration tests.
- The database is local-only; encryption, secure key storage, cloud sync, and
  multi-user access remain separate decisions.
