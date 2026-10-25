# ADR 0010: Test tagging and golden separation

## Status

Accepted.

## Context

Pixel goldens are platform-sensitive and require human image review. Mixing
them into the portable logic/widget suite made failures ambiguous and allowed
environment differences to obscure functional regressions.

## Decision

Tag screenshot comparisons `golden`. The normal quality gate runs all
non-golden tests; a separate Windows job runs golden tests, preserves failure
artifacts, and never updates baselines. Only the owner or assigned visual
reviewer regenerates goldens and records the manual review in
`docs/design/GOLDEN_REVIEW.md`.

## Consequences

Functional tests remain cross-platform and goldens retain a stable renderer.
Both jobs are required; tagging must never be used to hide a failing test.
