# M3 — Modbus and inverter foundation

Completed on 2026-10-17.

## Delivered

- Modbus RTU CRC16, T3.5 timing, partial/noisy stream decoding, exception
  responses, broadcast constraints, and functions 01/02/03/04/05/06/0F/10.
- Modbus TCP MBAP transaction, protocol, and length validation.
- Function/range guards; physical writes require both the existing write
  pipeline authorization and hardware-verified profile state.
- Device profile schema v2, v1 migration, bilingual field validation, JSON
  Schema artifact, and CI profile validation.
- Inverter adapter contract and deterministic Modbus inverter simulator.
- FRECON PV100/PV200 research-only profile based only on documented RS485
  settings. It contains no invented register addresses or fault codes; its
  connection test is disabled with “Register map required from manufacturer.”
- Extensible category field with the VFD product decision explicitly pending.

## Evidence

- `flutter analyze`: no issues.
- `flutter test --coverage`: 98 tests passed.
- Line coverage: 2151/2633 (81.7%).
- `dart run tool/profile_check.dart`: both bundled profiles valid.
- Android and Windows build results are recorded in the milestone commit handoff.

## Remaining external dependency

FRECON support cannot move beyond `researchTarget` until the manufacturer
provides an authoritative register map, scaling rules, firmware applicability,
fault dictionary, and test vectors with acceptable redistribution terms.
