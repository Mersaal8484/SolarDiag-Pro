# Gateway protocol contract

This contract is the host-side boundary for a future isolated SolarDiag gateway. It is implemented and tested without claiming that gateway hardware or firmware exists.

## Session establishment

The gateway sends a bounded JSON-lines `hello` message with protocol version, hardware and firmware revisions, an ephemeral boot identifier, physical TX-interlock status, and interface descriptors. Descriptors declare isolation, listen-only capability, and supported bit or baud rates. They are claims from unvalidated hardware, not proof of electrical compliance.

The host rejects unknown protocol versions, duplicate or missing interfaces, unisolated interfaces, absent TX interlocks, unsupported rates, and profiles that do not require listen-only operation. Passive plans cannot transmit. Active-read negotiation additionally requires a document- or hardware-verified read capability, explicit user start, and declared rate and bus-load limits. Write-mode negotiation is separate and requires hardware-verified write capability.

`FrameTransport` owns the transmission guard. Every send crosses it; passive mode rejects every send, active-read rejects writes, and rejected or rate-limited frames never reach the wire. Error frames force back-off. Mode and decisions enter the audit chain.

Messages are limited to 64 KiB and carry a monotonically increasing sequence number. Replayed and out-of-order messages are rejected. A reconnect resets sequence state and requires a new hello and negotiation.

## Intentionally absent

No USB/BLE/TCP connector, firmware flashing, arbitrary frame transmission, gateway trust attestation, or hardware validation is implemented. Active documented reads and verified writes remain behind the existing allow-list and verification policies and are not exposed by this passive contract.
