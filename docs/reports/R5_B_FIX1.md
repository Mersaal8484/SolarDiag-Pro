# Round 5 B-fix 1
- NOT RUN — owner will verify.
- Added the direct core battery-model import for `Measurement` and `DataAbsenceReason`.
- Confirmed diagnostics and inverter models import core directly; `ModuleStatus` use is covered.
- No simulator imports exist in core, diagnostics, or integration.
- Changed the schema test to import the pure-Dart validator by relative path.
- Confirmed the validator has a const constructor; both call sites remain const.
- Checked imports in contribution, diagnostics, golden/core screens, m2, profile schema, studio builder, and widget tests.
- No unresolved compile concern identified statically; owner verification is still required.
