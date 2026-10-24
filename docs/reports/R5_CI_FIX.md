# CI repair
- NOT RUN — owner will verify.
- The formatter failure was fixed in commit `1562a10`.
- The latest run then failed at `git diff --exit-code docs/CAPABILITY_MATRIX.md`.
- Root cause: unsorted recursive profile enumeration changed row order by runner OS.
- Sort profile paths before generating the matrix; reorder the checked-in output to match.
- Grep counts: `listSync` 1, `rows.add` 2, matrix path 1.
- No APIs/assertions changed; no Dart/Flutter commands or tests were run.
- Owner should run `dart run tool/generate_capability_matrix.dart` and verify CI.
- Uncertainty: generator output equivalence is inferred from its source and CI diff.
