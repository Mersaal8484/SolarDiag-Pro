# Gateway hardware requirements

This repository contains a host-side contract only. It does not contain ESP32
firmware and does not validate any physical gateway.

## Capability announcement

Before a session, firmware must announce a protocol version, hardware and
firmware revision, unique boot ID, physical TX interlock state, and every
isolated interface. CAN announcements list supported 125 kbit/s, 250 kbit/s,
500 kbit/s and 1 Mbit/s rates. Any other rate is rejected unless it is both
declared and identified as a validated custom bitrate. RS485 announcements list
supported baud rates. An announcement is a claim, not hardware evidence.

## Fail-closed operation

- Every session starts listen-only; passive negotiation cannot transmit.
- CAN TX requires an allow-listed identifier. RS485 TX requires an allow-listed
  unit address and function code. A miss is dropped and produces the
  `tx_allowlist_drop` audit action.
- Active reads require explicit start, verified capability, a positive frame
  rate, and a bus-load cap. Reaching either limit triggers back-off.
- Link health reports latency, errors, timeouts and CRC failures. CAN gateways
  additionally report nullable TEC, REC and bus-off state; absent evidence must
  remain unavailable rather than being reported as zero.
- High-voltage batteries remain monitoring-only unless the relevant capability
  is verified on hardware. The physical TX interlock remains mandatory.

## Electrical requirements

- Isolated CAN with hardware listen-only control, switchable 120 ohm
  termination, standard/extended identifiers, and bus-error reporting.
- Isolated RS485 with direction control, switchable termination/bias, and
  surge/ESD protection; protected RS232 and selectable 3.3/5 V UART.
- Galvanic isolation and isolated power sized and certified for the intended
  installation category, plus keyed connectors, documented pinouts, fusing,
  enclosure clearances, and certified high-voltage service interfaces.

Required validation includes qualified schematic and isolation/creepage review,
EMC/ESD and thermal testing, fault injection, bus-load/back-off verification,
and model-specific harness testing. None of that validation is represented by
the Dart contract.
