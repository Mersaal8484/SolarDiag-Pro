# R5-2 Repair 3

**NOT RUN — to be verified manually by the owner.** No Flutter/Dart commands or validation tools were run.

- **H1:** `parameters_screen.dart` now renders the shared PIN dialog as `_PinDialog`; it owns and disposes its controller after dialog removal, clears the field before submit, and keeps localized labels. Both unlock flows use it.
- **H2:** Checked all feature references: both confirmation sites already call `createConfirmationToken` with the reviewed diff hash and current device/session IDs. No direct constructor remains in feature code.
- **H3:** `AuditChain.load` requires a secret and valid MAC for every persisted chain; persistent append fails before mutation if the key is unavailable. File/database loaders reject orphaned MAC metadata; missing, invalid, or replaced chain data fails closed.
- **H3 coverage:** `audit_chain_test.dart` checks authenticated restore, tampered entries/head/MAC, missing key/MAC, empty-chain replacement, and blocked persistent append.
- **H4:** The R5-2 profile fixture already includes the required list of `{start, end}` maps, matching `DeviceProfile._maps`.

Owner must run: `dart format lib test tool`; `flutter analyze --fatal-infos`; `flutter test`.

**Compile uncertainty:** No compile or test verification was run; formatting and the static audit-HMAC paths require owner validation.
