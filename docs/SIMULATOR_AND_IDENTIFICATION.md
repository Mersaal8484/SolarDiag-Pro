# Simulator and automatic identification

The deterministic simulator provides nominal, imbalanced-cell, active-alarm, intermittent-link, and missing-temperature scenarios. Timestamps and values are derived from an explicit tick so tests are reproducible.

Automatic identification is an explicit state machine. It observes passively first, filters profiles by the gateway interface, and confirms a unique passive match when possible. A safe query is attempted only through `TransmissionGuard` using a profile-declared read identifier. No write probe or arbitrary address sweep exists.

Ambiguous matches stop for user confirmation. No match is reported as unsupported rather than guessed.
