# R5-2 Repair 5

- Status: NOT RUN — no Flutter/Dart tools or checks were run.
- L1: Added `AuditAvailability`; missing/unusable keys keep audit entries memory-only and unsigned, block write-pipeline operations with `auditKeyUnavailable`, and show a localized EN/AR warning. Gateway mode logging no longer runs in its constructor.
- L2: Added test-only `TestSecretStore` using `Random.secure`; injected it into persistence/write/UI fixtures. Added no-key read/warning and keyed persistence coverage.
- L3-L4: Updated the audit-store fake; missing/invalid MAC and replacement chains fail closed. Added file-store and database-store MAC coverage.
- L5-L6: `lib/features` contains only factory calls to `createConfirmationToken`; the corrected Y4 fixture remains in place.
- Root causes: build-time gateway append attempted durable storage without a key; writes did not expose a key-unavailable result; audit persistence lacked a database MAC column.
- Static grep checked all `AuditChainStore` implementers (file, database, two test fakes), `DeviceSession` constructors, and confirmation-token sites.
- Also checked the `SecretStore` production/test implementations and `ValidationCode` callers.
- Owner must run: `dart format lib test tool`, `flutter gen-l10n` (ARB changed; generated files updated manually), `flutter analyze --fatal-infos`, `flutter test`, `profile_check`, `reference_check`.
- Compile correctness remains unverified, especially generated localization consistency, Windows secure-storage registration, SQLite migration behavior, and file-store rename behavior.
