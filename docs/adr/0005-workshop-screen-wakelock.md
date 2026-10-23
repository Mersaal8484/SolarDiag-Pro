# ADR 0005: Workshop screen wakelock

## Status

Accepted.

## Context

Workshop mode requires large controls and an option to keep the display awake
during an active diagnostic session. Flutter has no cross-platform screen
wakelock API.

## Decision

Use `wakelock_plus` 1.8.x from the verified `fluttercommunity.dev` publisher.
SolarDiag toggles only the screen wakelock when workshop mode changes and
disables it when the application scope is disposed. The plugin requires no
special platform permission and does not keep the CPU alive in the background.

## Consequences

- Workshop sessions remain readable without touching the display.
- The setting is explicit, local, persisted, and disabled by default.
- No network, telemetry, or analytics capability is introduced.
