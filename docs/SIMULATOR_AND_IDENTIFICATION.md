# Simulator and automatic identification

The deterministic simulator provides nominal, imbalanced-cell, active-alarm, intermittent-link, and missing-temperature scenarios. Timestamps and values are derived from an explicit tick so tests are reproducible.

Automatic identification is an explicit state machine. It observes passively first and filters profiles by gateway interface. A single identifier match yields `needsConfirmation`; automatic confirmation requires at least two independent evidence types such as identifier fingerprint plus payload structure/periodicity, or a documented identity response. Active queries use the guard owned by `FrameTransport`, with per-query timeouts, bounded retries, and a global budget. Manual manufacturer/family/model/firmware selection is exact, explicitly flagged, and carries a wrong-decoding warning. No write probe or arbitrary address sweep exists.

Ambiguous matches stop for user confirmation. No match is reported as unsupported rather than guessed.
