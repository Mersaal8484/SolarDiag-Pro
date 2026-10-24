# R5-2 Repair 2

**NOT RUN — to be verified manually by the owner.** No formatter, generator, analyzer, test, or build was run.

- **G1 —** `parameters_screen.dart`: `_ensureUnlocked` referenced undefined `s`; now resolves `AppLocalizations.of(context)`. Verified all PIN dialog keys exist in both ARBs and generated locales.
- **G2 —** `parameters_screen.dart` already uses `createConfirmationToken` for the shown diff, device ID, and session ID; static search found no direct `ConfirmationToken` constructor in feature code, so no change needed.
- **G3 —** `audit_chain.dart`: non-empty loaded chains now require a secret store and non-empty valid head MAC. The same loader validates file/database store results. `audit_chain_test.dart` now covers successful authenticated restoration, missing MAC, loading without a secret store, and entries+head replacement retaining the original MAC.
- **G4a —** `r5_2_trust_and_safety_test.dart`: its profile fixture omitted `allowed_modbus_read_ranges`; `DeviceProfile._maps` expects a list of map objects, so a valid start/end range was added.
- **G4b —** `t1_safety_and_trust_test.dart`: `isApprovedFor` rejects missing hardware validation IDs; the valid fixture now has one and a separate empty-ID rejection test was added.
- **G5 —** `t1_safety_and_trust_test.dart`: successful unlock cases used the fail-closed default, leaving `auth.current` null; injected demo authentication only in unlock-dependent tests. Widget PIN flows already enter the real field; device-session/widget demo injection remains test-only.

Owner must run: `dart format lib test tool`; `flutter gen-l10n`; `flutter analyze --fatal-infos`; `flutter test`.

Compile uncertainty: the generated localization sources were hand-edited in Repair 1; run `flutter gen-l10n` to confirm generator consistency.
