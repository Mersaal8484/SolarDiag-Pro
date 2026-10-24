# R5-2 Repair

## F1 — Revocation sequence store contract

- **Files changed:** `lib/trust/signed_tokens.dart`, `test/contribution_platform_test.dart`, `test/r5_2_trust_and_safety_test.dart`.
- **Root cause:** `LibraryPackStore` did not declare the revocation sequence load/save contract, even though `LibrarySync` needs that persisted anti-rollback state.
- **Change:** Made both methods required on `LibraryPackStore`, rather than relying on a zero/no-op default. `FileLibraryPackStore` persists the sequence through a flushed temporary file followed by rename; the in-memory test fakes implement the contract. `LibrarySync` waits for the persisted floor before pack/revocation operations and persists accepted updates. The R5-2 test verifier fake supports those trust-flow tests.
- **Grep review:** Checked all `LibraryPackStore` implementers (`FileLibraryPackStore`, `_MemoryPackStore`, `_TestPackStore`) and all load/save callers in `LibrarySync` (initial state load, sequence recording, pack application, and revocation refresh). All implementers provide both methods, and all `LibrarySync` paths use the required interface methods.

## F2 — Invalid `const` pack declarations

- **Files changed:** `test/r5_2_trust_and_safety_test.dart`.
- **Root cause:** Three `const LibraryPack` values used `DateTime.utc(2027)`, which is not a compile-time constant.
- **Change:** Changed those declarations to `final` and aligned their expiry arguments with `LibraryPack`'s `DateTime` field; the represented dates and assertions are unchanged.
- **Grep review:** Checked all three `expiresAt: DateTime.utc(2027)` initializers in the R5-2 test. Other matches in different tests are runtime initializers and were not changed.

## F3 — PIN UI design-system and localization violations

- **Files changed:** `lib/features/parameters_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, `lib/l10n/generated/app_localizations.dart`, `lib/l10n/generated/app_localizations_en.dart`, `lib/l10n/generated/app_localizations_ar.dart`.
- **Root cause:** The PIN authorization dialog in `ParametersScreen` used literal English `Text` strings rather than localization getters. The screen already used theme palette tokens for its colors; no direct color literal needed replacing.
- **Change:** Added English and Arabic strings for the dialog title, PIN label, hint, and authenticate action, and added matching getters/translations to the generated localization sources. The dialog also uses the existing localized cancel string.
- **Grep review:** Searched `parameters_screen.dart` for literal `Text` strings, direct `Colors` usage, and `Color(0x...)`; none remain. Checked each new localization key in both ARB files and all three generated localization files.

## F4 — Session and widget authentication failures

- **Files changed:** `test/device_session_test.dart`, `test/widget_test.dart`, `test/r5_2_trust_and_safety_test.dart`.
- **Root cause:** `DeviceSession` correctly defaults to `NoAuthenticator`, which always rejects credentials. The affected session tests called `unlock` with `"pin"` but did not inject a demo/test authenticator. The parameter UI test also had not entered the PIN into the real dialog; the backup-restore test's setup attempted to authenticate using the rejecting default.
- **Change:** Injected `DemoConfiguration(isDemoMode: true, demoPin: 'pin')` only in the tests that need successful writes. Widget tests enter the PIN into the rendered `TextField` and submit the authentication action; the restore UI test locks the session before exercising its PIN dialog. Production authentication remains fail-closed. Extended the default-authenticator coverage to verify that a default `DemoConfiguration` also rejects its supplied PIN. Existing demo coverage verifies successful authentication and rejection of a wrong PIN.
- **Grep review:** Searched every `auth.unlock` and `DeviceSession` construction in `device_session_test.dart` and `widget_test.dart`; the four direct session write tests and both write-flow widget tests now inject the demo authenticator, while read-only cases retain the default. Checked `NoAuthenticator`, `MockTechnicianAuthenticator`, and all R5-2 default/demo/wrong-PIN assertions.

## Owner must run: `dart format`, `flutter gen-l10n` (if ARB changed), `flutter analyze --fatal-infos`, `flutter test`, `profile_check`, `reference_check`

- Run the listed checks manually; no formatter, generator, analyzer, build, or test command was run for this repair.
- **Compile-correctness uncertainty:** The generated localization files were updated to match the repository's current generated-code pattern by hand. Confirm their exact consistency by running `flutter gen-l10n`; no other unresolved compile concern was identified by static inspection.
