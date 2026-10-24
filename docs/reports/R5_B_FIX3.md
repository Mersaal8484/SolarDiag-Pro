# Round 5 B-fix 3
- NOT RUN — owner will verify.
- Updated `_format` to accept nullable evidence and render null through `notAvailable`.
- Its sole caller passes `finding.evidence` map values.
- Other evidence use is serialization or iteration; no non-nullable display argument found.
- No ARB keys or call sites changed.
- No Dart/Flutter tools or tests were run.
