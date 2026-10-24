# `.sdcap` capture format

Version 2 is a UTF-8 JSON container with magic `SOLARDIAG_CAPTURE`, schema
version, payload and a SHA-256 integrity hash over the encoded payload. SHA-256
detects modification; it is not an identity signature.

The generic frame stores raw bytes, direction, channel, nanosecond timestamp,
optional source/destination addresses, error flags, protocol hint and optional
CAN identifier/extended flag. The session stores interface/source, serial/CAN/
network configuration, device metadata, clock source and accuracy, integrity
hash, synthetic status and the NDA restriction marker.

The reader accepts version 1 CAN/microsecond documents and migrates them into
the generic in-memory model. Writers emit version 2 only. Unknown, malformed or
integrity-invalid documents fail closed.

Implemented importers are `.sdcap` v1/v2, candump, SLCAN (`t`, `T`, `r`, and
`R` records), mapped CSV and generic hex text. Importers are tolerant at the
file level and report malformed source line numbers. PCAP/PCAPNG Modbus TCP and
Vector ASC are explicitly unsupported.

NDA-marked sessions may be encoded only through the explicit local-persistence
path. Normal `.sdcap` and research-bundle exports reject them.
