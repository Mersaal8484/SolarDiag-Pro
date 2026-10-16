# ADR 0001: Declarative device profiles

Status: accepted

Device identity, provenance, transport requirements, capability verification, and frame allow-lists are data. Protocol-family framing and parsing remain code behind `BmsAdapter`.

The first schema is deliberately strict and only the deterministic simulator is bundled. Unsigned physical profiles are rejected in technician mode. Cryptographic pack signatures and schema-driven telemetry maps will be introduced before any physical profile can ship.
