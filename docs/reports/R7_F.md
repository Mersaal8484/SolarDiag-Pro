# Round 7 — Batch F

- F1: split transport/authorization sources; simulator adapters are standalone;
  safety roots have no direct `simulator/` imports; raw commit stays private.
- F2: `checkWrite` is private; reads require `ModbusRegisterKind`; RTU idle-gap
  and response-address-zero behavior have tests.
- F3: Android release signing reads `android/key.properties`, never debug-signs
  release, and fails release tasks when required values are absent.
- F4: ADRs are one sequence (`0001`–`0010`); added single-package,
  SecretStore, schema-validation, and test-tagging decisions.
- F5: corrected T1 IDs; added honest T2/T3/T4 and R7 summary reports.
- Signature grep: 2 authorization mint helpers updated; 10 read calls and 10
  explicit register kinds; 0 public `checkWrite(` call sites.
- Architecture grep: 0 direct `simulator/` imports in parameters/session/
  protocols/transport/auth/trust; the factory definition is explicitly exempt.
- Signing grep: 0 debug signing assignments; ADR count: 10.
- Imports were reviewed manually; no profile/schema fixture changed.
- Architecture patterns were checked against new names; ARB files were unchanged.
- Owner verification: `analyze --fatal-infos` reported 0 issues; T1 (26), T2
  (18), and R5 Modbus (14) tests passed after the reported fixes.
- Uncertainty: Gradle Kotlin signing configuration needs owner evaluation.
- NOT RUN — owner will verify. No formatter, generator, analyzer, test, build,
  golden update, image review, hardware check, or release signing was run.

Owner: `dart format lib test tool`; `flutter analyze --fatal-infos`;
`flutter test test/t1_safety_and_trust_test.dart test/t2_correctness_test.dart test/r5_modbus_client_test.dart`;
then `flutter test --exclude-tags golden`.
