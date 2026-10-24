# R5 A-verify — Z1

- NOT RUN — owner will verify.
- Existing Z1 implementation includes required `ModbusGuard`, RTU/TCP/loopback links, MBAP transaction checks, RTU partial-frame collection/inter-frame delay, function selection, length/byte-count/PDU/address checks, and pipeline-only single-use write authorization.
- Grep found 0 `pipelineAuthorized` occurrences in `lib/` and `test/`; all 18 `ModbusClient` construction call sites in tests provide a guard.
- Grep found 3 production `ModbusLink` implementations and 2 test fakes; the interface signature is consistent.
- Existing test cases cover RTU/TCP simulator reads, loopback, blocked I/O, missing/reused authorization, timeout, exception, byte-count mismatch, oversized PDU, and RTU address zero.
- Added a test for authorization binding to function code, address, register count, and value hash.
- Grep found the private authorization constructor only in `VerifiedWritePipeline`; no delayed-timeout/no-transport mode was found in production Modbus code.
- Changed files: `test/r5_modbus_client_test.dart`, this report.
- No known compile concerns; validation remains for the owner.
