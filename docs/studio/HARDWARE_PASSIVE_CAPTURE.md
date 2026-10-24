# Hardware passive capture contract

SolarDiag Pro does not currently ship a physical capture adapter. This document
defines the minimum contract for one. A gateway is not supported merely because
it can produce frames; it must satisfy every control below and pass dedicated
hardware validation.

## Electrical and transport requirements

- Use galvanic isolation appropriate to the target bus and installation class.
- Default CAN, RS485, RS232 and UART capture to receive/listen-only operation.
- CAN auto-bitrate may observe traffic but must never transmit probe frames.
- Do not add termination or bias unless the installer explicitly verifies that
  the bus requires it. Incorrect termination can disrupt safety equipment.
- Record interface configuration, channel, gateway identity, firmware, bus
  error counters and timestamp source in `CaptureSession` metadata.
- Timestamp at the gateway with a monotonic nanosecond clock. Record estimated
  clock accuracy; do not imply accuracy that was not measured.
- Preserve malformed, truncated and error frames with error flags rather than
  silently normalizing them into valid traffic.

## Safety boundary

Captured or derived bytes must never be routed into a transmit API. Replay Lock
is a domain boundary, not only a disabled button. Technician mode must not expose
arbitrary transmit controls. Any future active test requires a separate reviewed
design, explicit device allow-list, authenticated approval, write guards and
isolated-hardware validation.

## Acceptance evidence

A physical adapter remains **unavailable** until tests demonstrate isolation,
listen-only behavior, timestamp accuracy, sustained ingestion, overflow/error
reporting and safe disconnect behavior on every advertised interface. Synthetic
and imported captures do not constitute physical hardware validation.

Imported captures enter through the Studio wizard, which records source,
interface settings, device metadata, clock source, and clock accuracy. Large
captures must use bounded streaming analysis instead of materializing every
frame in the UI. Before a draft leaves the research workspace, redact secrets
and identifiers and complete `LEGAL_REVIEW_CHECKLIST.md`; the release gate still
requires separate authorized physical-hardware evidence.
