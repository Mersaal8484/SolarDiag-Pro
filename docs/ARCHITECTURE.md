# System architecture

The Flutter application follows one-way dependencies: features consume domain/services; diagnostics and integration consume core values; protocol adapters consume transport abstractions; UI never builds raw frames. The deterministic simulator implements the same adapter boundary as future hardware.

Major modules: `core`, `protocol`, `transport`, `identification`, `simulator`,
`diagnostics`, `parameters`, `integration`, `session`, `persistence`, `reports`,
`studio`, `contribution`, `trust`, `audit`, `features`, and `app`.

`TelemetrySnapshot` is the canonical BMS telemetry boundary. Measurements retain value, unit, source timestamp, quality, freshness policy, and absence reason. The deterministic simulator implements the same `BmsAdapter` surface for telemetry, cell measurements, alarms, parameters, capabilities, health, and pipeline-only parameter transport.

The `gateway` module defines the bounded, replay-resistant host contract and fail-closed passive-session negotiation for a future isolated gateway. It contains no hardware connector and cannot enable transmission; see `GATEWAY_PROTOCOL.md`.

`DeviceSession` is the application state boundary. It owns the active adapter,
approximately 2 Hz polling, link health, telemetry, alarms, parameter readback,
verified simulated writes, and configuration backup/restore. Screens consume it
through `DeviceSessionScope`; displayed link and diagnostic state is derived
from the active session rather than copied constants.

`LocalDatabase` owns the SQLite schema for diagnostic sessions and parameter
backups. Successful telemetry is serialized with explicit quality and absence
metadata and stored with a SHA-256 hash. The report service verifies that hash
before generating JSON or PDF and rejects any report request that mixes real
and simulated records. See `adr/0003-local-sqlite-persistence.md`.

The schema's second migration adds local application settings. It currently
stores first-run onboarding completion. The adaptive `WorkspaceShell` keeps a
five-item phone navigation bar and a complete desktop rail; named routes expose
battery, inverter, link, library, history, gateway, parameters, diagnostics and
the Design Lab directly.

Safety boundaries are `TransmissionGuard`, `VerifiedWritePipeline`, `ReplayLock`, `ProfileRegistry`, contribution lifecycle gates, and signed-token validation. Current project layout is a single Flutter package; extraction into independent workspace packages remains a scaling refactor, not a functional claim.
