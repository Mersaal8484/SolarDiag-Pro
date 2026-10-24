# CI formatting repair
- NOT RUN — owner will verify.
- Root cause: `dart format --set-exit-if-changed` reported three test files as changed.
- Exact CI line: `Changed test/audit_chain_test.dart`.
- Reformatted nested file writes in `test/audit_chain_test.dart` without changing assertions.
- Wrapped report-building calls in `test/engineering_report_test.dart`.
- Split long literals and aligned imports in `test/t1_safety_and_trust_test.dart`.
- Grep review: 10 report builder calls and 53 T1 expectations retained.
- `git diff --check` reported no whitespace errors; no project checks were run.
- Unsure: pinned CI formatter was not run here; owner must rerun the workflow format step.
