# ADR 0008: Single Flutter package

## Status

Accepted for the current product stage.

## Context

SolarDiag contains application UI, pure-Dart protocol and analysis code,
offline persistence, simulator support, and validation tools. Splitting these
into workspace packages now would add publication boundaries and dependency
coordination before real hardware interfaces stabilize.

## Decision

Keep one Flutter package with explicit directories and static architecture
tests. Pure-Dart domains must not import Flutter services, and safety-critical
production roots must not import simulator implementations. Composition code
is the only place allowed to select concrete simulator adapters.

## Consequences

Refactoring is faster and CI has one dependency graph. Directory boundaries
are conventions enforced by tests rather than package privacy. Reconsider a
multi-package workspace when a reusable gateway SDK or independently released
protocol library has a real consumer.
