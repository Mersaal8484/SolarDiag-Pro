# Round 7 - Batch G

- G1: added strict PEAK TRC, Vector ASC and SLCAN capture importers with
  line-numbered errors; added deterministic DBC/KCD CAN signal import/export.
- Unsupported formats are exactly: `pcap Modbus TCP`, `pcapng Modbus TCP`,
  `serial-sniffer binary logs`, `serial-monitor vendor exports`; docs/code/test
  contain the same four entries.
- G2: added bounded one-pass inference for address fields, response latency and
  derived timeout, payload length, ASCII/BCD/hex-ASCII, ranked numeric
  endianness/signedness/scale, bit correlation and CAN signal boundaries.
- Findings remain observations with computed capture evidence; none are marked
  confirmed, verified, or hardware-validated.
- Synthetic suite: 5 labelled sessions; the million-frame test uses a lazy
  iterable and asserts bounded estimated analysis state.
- G3: all 10 required sections already exist: Sessions, Capture, Frames,
  Analysis, Differential, Hypotheses, Profile Builder, Mapping, Validation,
  Export. Android now exposes all ten through the existing app-bar language.
- G4: Replay Lock rejects before a recording writer is called; static scan
  found 0 Studio imports of `transport/` or `gateway/` and 0 writer invocations.
- G5: reused-code references now require SPDX license, legal review, notice flag
  and complete generated notice content; the CLI invokes this validation.
- Signature review: 8 new public G APIs have direct lib/test call sites.
- Fixtures were checked against each parser; malformed rows are not repaired.
- Imports and architecture scan patterns were reviewed manually; ARB parity is
  unchanged because no localization key was added.
- Owner analyzer final: clean. Four off-by-one fixture expectations were
  corrected; owner rerun passed all 10 importer tests.
- Studio golden remains pending owner regeneration/review under Batch K rules.
- Owner tests passed: inference 7, Studio core 17, E2E 3; 6 references valid.
  Build, golden/image review and hardware checks remain NOT RUN.
