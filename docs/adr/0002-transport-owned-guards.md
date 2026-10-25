# ADR 0002: transport-owned guards and transport-derived simulation

Status: accepted, 2026-10-17.

Frame policy belongs to `FrameTransport`, not to identification or UI callers. Every send is evaluated by the transport-owned `TransmissionGuard` before the loopback wire boundary. Passive mode cannot send; active-read mode accepts documented reads only; write mode remains separately negotiated. This prevents a feature from constructing a permissive local guard.

Parameter transports are sealed implementations whose immutable kind is selected at construction. Physical construction always reports `physical`; simulator construction originates from the standalone simulator library. The write pipeline reads this property and has no caller-supplied simulation flag. The raw commit member remains library-private to the verified pipeline.

No dependency was added. This decision is enforced by safety and architecture tests. It does not prove isolation or physical-interlock behavior on real hardware.
