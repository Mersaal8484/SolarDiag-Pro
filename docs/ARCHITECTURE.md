# System architecture

The Flutter application follows one-way dependencies: features consume domain/services; diagnostics and integration consume core values; protocol adapters consume transport abstractions; UI never builds raw frames. The deterministic simulator implements the same adapter boundary as future hardware.

Major modules: `core`, `protocol`, `transport`, `identification`, `simulator`, `diagnostics`, `parameters`, `integration`, `studio`, `contribution`, `trust`, `audit`, `features`, and `app`.

Safety boundaries are `TransmissionGuard`, `VerifiedWritePipeline`, `ReplayLock`, `ProfileRegistry`, contribution lifecycle gates, and signed-token validation. Current project layout is a single Flutter package; extraction into independent workspace packages remains a scaling refactor, not a functional claim.
