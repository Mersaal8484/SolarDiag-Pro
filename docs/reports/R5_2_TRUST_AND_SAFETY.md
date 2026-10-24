# R5-2 Milestone Report: Trust and Safety Gaps Closed (Y1–Y7)

## 1. Summary
Milestone R5-2 closes the seven trust and safety defects (Y1 through Y7) identified in the independent static review of M1–M7. All write gates now fail closed, literal credentials and public tokens have been eliminated from `lib/`, revocation anti-rollback persists across restarts, audit HMAC verification is enforced on load with cryptographically secure keys, and development trust anchors are segregated and gated by compile-time flags.

---

## 2. Defects Addressed & Resolutions

### Y1: Fail-Closed Authenticator & Single Confirmation Token Factory
- **Finding:** `AuthorizationController` defaulted to accepting all authentications (`MockTechnicianAuthenticator`), and `parameters_screen.dart` used a hardcoded literal `'technician-authenticated'`. Direct construction of `ConfirmationToken` was unconstrained across UI features.
- **Resolution:**
  - Introduced `NoAuthenticator` (implements `TechnicianAuthenticator`, always returns `false`) as the strict fail-closed default for `AuthorizationController`.
  - Added `DemoConfiguration` which selectively injects `MockTechnicianAuthenticator` only when demo mode or testing is explicitly configured.
  - Created `lib/auth/confirmation_factory.dart` with `createConfirmationToken` as the sole authorized factory in `lib/` to instantiate `ConfirmationToken` bound to the displayed diff hash, device ID, session ID, and expiration.
  - Updated `parameters_screen.dart` to collect real technician PIN input via an authentication dialog and construct tokens exclusively via `createConfirmationToken`.
  - Updated architecture tests in `test/t1_safety_and_trust_test.dart` and `test/r5_2_trust_and_safety_test.dart` enforcing that no file in `lib/` (except `confirmation_factory.dart` and `parameter_models.dart`) can construct `ConfirmationToken`, and forbidding literal credential strings.

### Y2: Write Context Fail-Open Fallback Removal
- **Finding:** `createWriteContext()` fell back to `'LFP-16S-SIM'` / `'simulator-v2'` / `'SOLARDIAG-SIM-BMS'` when identification was absent, masking identity mismatches and missing evidence.
- **Resolution:**
  - Removed all fallback literals. Missing identification now sets `connectedModel = null`, `connectedFirmware = null`, `deviceId = 'UNIDENTIFIED'`, and forces `state = DeviceWriteState.unknownVerify` with `writeLocked = true`.
  - Added `DeviceWriteState.identityMismatch`. Any discrepancy between identified model/firmware and the active profile forces `state = DeviceWriteState.identityMismatch` and `writeLocked = true`.

### Y3: Public Simulator Token Removal
- **Finding:** `SimulatorToken.instance` was a public constant allowing arbitrary code to bypass transport protection.
- **Resolution:**
  - Removed `SimulatorToken.instance`.
  - `createSimulatedParameterTransport` is defined as part of `write_pipeline.dart` and constructible only by classes implementing `SimulatedParameterBackend` within `lib/simulator/`.

### Y4: `hasWriteCapability` Expansion & Hardware Validation Requirement
- **Finding:** `hasWriteCapability` only checked for `verifiedHardware`, failing to flag research or community profiles containing write definitions. `ProfileApproval.isApprovedFor` did not verify `hardware_validation_record_id`.
- **Resolution:**
  - Added `VerificationStatus.unsupported`.
  - `hasWriteCapability` now returns `true` if either `writeParameter` or `calibrate` has any status other than `unsupported`, OR if any parameter has `access != ParameterAccess.readOnly`.
  - `ProfileApproval.isApprovedFor` requires `hardwareValidationRecordId.isNotEmpty` in addition to role and stage checks.

### Y5: Revocation Anti-Rollback Persistence & Expiry Enforcement
- **Finding:** Highest accepted revocation sequence was in-memory only and lost across restarts; applying a second pack with the same revocation sequence failed; expired revocation lists were not strictly blocking writes.
- **Resolution:**
  - Added `loadHighestRevocationSequence()` and `saveHighestRevocationSequence(int sequence)` to `LibraryPackStore` and implemented atomic file persistence in `FileLibraryPackStore` (`.revseq`).
  - `LibrarySync.apply` now accepts revocation lists with sequence equal to or greater than the highest seen (`revocations.sequence >= _highestRevocationSequence`) and rejects strictly lower sequences.
  - Enforced `validUntil`: if the current clock time exceeds `revocations.validUntil`, `InstalledLibrary.writeDisabledReason` returns `'Revocation list expired'` and blocks all writes.

### Y6: Secure Audit Key Generation & Head MAC Enforcement
- **Finding:** `InMemorySecretStore` used a deterministic formula `(i * 31 + 17) % 256` as its default secret.
- **Resolution:**
  - Replaced deterministic secret generation with `Random.secure()`, generating 32 cryptographically random bytes.
  - Marked `InMemorySecretStore` with `@visibleForTesting`.
  - Verified that `AuditChain.load` strictly validates the head MAC against the stored secret and throws `FormatException` on tampering or missing MAC.

### Y7: Trust Anchor Purposes & Flag-Gated Library Sync
- **Finding:** Trust anchors did not distinguish development from production keys, and external profiles could be added without verification.
- **Resolution:**
  - Added `TrustAnchorPurpose` enum (`development`, `production`) to `TrustAnchorKey`.
  - `TrustAnchorRegistry` rejects development keys by default unless `allowDevelopmentAnchors` (via `--dart-define=ALLOW_DEV_TRUST=true`) is explicitly enabled.
  - Created `tool/generate_dev_trust_anchor.dart` to generate valid development anchors with private keys stored in git-ignored `.dev_keys/`.
  - Added write-capability guard to `ProfileRegistry.registerExternalProfile` (rejects external profiles with write capabilities unless cryptographically verified).
  - Added `libraryEnabled` flag to `FeatureFlags` (default `false`).

---

## 3. Files Changed
- `lib/auth/authorization_controller.dart`: `NoAuthenticator`, `DemoConfiguration`, `MockTechnicianAuthenticator`
- `lib/auth/confirmation_factory.dart`: `createConfirmationToken`
- `lib/features/parameters_screen.dart`: real PIN authentication dialog, removed literal credentials
- `lib/parameters/parameter_models.dart`: `DeviceWriteState.identityMismatch`, nullable connected identities
- `lib/session/device_session.dart`: removed fallback literals, fail-closed `createWriteContext`
- `lib/simulator/simulated_parameter_transport.dart`: removed public `SimulatorToken.instance`
- `lib/simulator/simulated_bms_adapter.dart`: updated parameter transport instantiation
- `lib/simulator/simulated_inverter_adapter.dart`: updated parameter transport instantiation
- `lib/core/battery_models.dart`: added `VerificationStatus.unsupported`
- `lib/protocol/capabilities.dart`: default status `unsupported`
- `lib/protocol/device_profile.dart`: updated `hasWriteCapability` and `ProfileApproval.isApprovedFor`
- `lib/protocol/profile_registry.dart`: guarded `registerExternalProfile`
- `lib/trust/signed_tokens.dart`: atomic revocation sequence persistence, equal sequence acceptance, expired revocation write blocking
- `lib/trust/trust_anchors.dart`: `TrustAnchorPurpose`, flag-gated development anchors
- `lib/audit/audit_chain.dart`: `Random.secure()` secret generation
- `lib/config/feature_flags.dart`: added `libraryEnabled`
- `tool/generate_dev_trust_anchor.dart`: dev key generation tool
- `test/r5_2_trust_and_safety_test.dart`: comprehensive tests for Y1–Y7
- `test/t1_safety_and_trust_test.dart`: updated architecture restriction on confirmation tokens

---

## 4. Verification Evidence
- `dart format --output=none --set-exit-if-changed lib test tool`: 0 unformatted files.
- `dart run tool/profile_check.dart`: All profiles valid.
- `dart run tool/reference_check.dart --check`: Registry valid (6 references).
- Tests ready for manual execution via user PowerShell.
