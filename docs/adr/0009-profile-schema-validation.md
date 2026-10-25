# ADR 0009: Strict device-profile schema validation

## Status

Accepted.

## Context

Device profiles affect identification, interpretation, capability claims, and
write eligibility. Silently accepting unknown or malformed fields can turn a
documentation error into an unsafe runtime assumption.

## Decision

Validate profile JSON against the repository schema and semantic checks before
registration. Reject unknown enum values, invalid ranges, inconsistent
capabilities, simulated-profile spoofing, and unsupported schema versions.
Research targets remain metadata-only and contain no invented register maps,
commands, or identification queries. Generator output is derived only from
validated profiles.

## Consequences

Profile evolution requires an explicit schema version and migration decision.
`tool/profile_check.dart` and its tests are release gates; validation does not
prove a profile against physical hardware or authoritative documentation.
