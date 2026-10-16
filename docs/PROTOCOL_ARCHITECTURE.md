# Protocol architecture

`BmsAdapter` is the protocol-family boundary. UI code never constructs frames. Profiles declare identity, provenance, transport, per-capability verification, and read allow-lists. `TransmissionGuard` is the final policy boundary before a future hardware transport.

Current implementation is intentionally simulator-only. The registry blocks unsigned physical profiles in technician mode, and no real manufacturer frame or register map is present.

## Next additions

- Canonical profile serialization, SHA-256 hashes, and Ed25519 pack signatures.
- Firmware-range comparison strategies.
- Telemetry and alarm maps with localized meanings.
- CAN bitrate validation, standard/extended identifiers, filters, rate limits, and bus-load cap.
- Gateway capability handshake and audit events.
