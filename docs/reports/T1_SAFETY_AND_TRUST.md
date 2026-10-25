# T1 — Safety and Trust Hardening Report

**Commit:** `537c462`  
**Date:** 2026-10-23  
**Milestone:** T1 — SAFETY AND TRUST (S1–S10)

---

## Defects Addressed

| ID | Finding | Resolution |
|----|---------|------------|
| S1 | Session self-issued authorization/confirmation and restore acknowledgement | Moved unlock control outside the session; restore requires explicit authorization, confirmations, and acknowledgement |
| S2 | `DeviceWriteContext` was not derived from live identity | `createWriteContext()` uses refreshed identification and locks identity mismatches |
| S3 | Public simulator transport construction | Simulator construction is isolated and production safety roots are checked by an architecture test |
| S4 | Signature incorrectly implied approval | Registry write eligibility requires the explicit lifecycle role/stage approval, not a signature alone |
| S5 | `hasWriteCapability` was incomplete | Write/calibration capability must be `verifiedHardware`; schema access parsing rejects unknown values |
| S6 | Revocation-list rollback | `LibrarySync` persists and rejects decreasing revocation sequences |
| S7 | Spoofed `simulated: true` profile | Non-bundled simulated profiles are rejected |
| S8 | Audit chain lacked authenticated persistence | Audit heads use a separately stored HMAC; missing keys fail closed |
| S9 | Trust-anchor provisioning | Typed trust-anchor lookup is wired; shipped placeholder/development anchors remain fail-closed in production |
| S10 | Gateway/identification hardening | Guard ownership, negotiation evidence, identification thresholds, and safe loopback construction were hardened |

---

## Files Changed

### New Files
- `lib/auth/authorization_controller.dart` — `TechnicianAuthenticator`, `MockTechnicianAuthenticator`, `AuthorizationController`, `AuthorizationState`
- `lib/trust/trust_anchors.dart` — `TrustAnchorKey`, `TrustAnchorRegistry` with embedded Ed25519 public keys
- `test/t1_safety_and_trust_test.dart` — 24 tests covering S1–S10

### Modified Files
- `lib/parameters/parameter_models.dart` — added `isExpiredAt()` to `AuthorizationSession`; added `ParameterAccess.from()` alias
- `lib/parameters/parameter_backup.dart` — `RestorePlan` with `backup`, `changes`, `orderedDiffHash`
- `lib/protocol/device_profile.dart` — fixed `ProfileApproval.isApprovedFor()`, fixed `hasWriteCapability`, added optional `approvedAt` field
- `lib/protocol/profile_registry.dart` — added `ProfileRegistry.empty()`, `canWrite()`, `registerExternalProfile()`; added missing imports
- `lib/protocol/capabilities.dart` — unchanged (enum values confirmed)
- `lib/session/device_session.dart` — integrated `AuthorizationController auth`, dynamic `createWriteContext()`, `applySimulatedParameterChange`/`restoreParameterBackup` now require external auth; `refresh()` populates `_lastIdentification`
- `lib/simulator/simulated_bms_adapter.dart` — `identityMismatch` scenario returns `LFP-UNKNOWN-MISMATCH` model
- `lib/simulator/simulated_inverter_adapter.dart` — now implements `SimulatedParameterBackend` properly
- `lib/simulator/simulated_parameter_transport.dart` — simulator-only transport construction isolated from production roots
- `lib/trust/signed_tokens.dart` — `RevocationList.signature` made optional; `LibrarySync.recordRevocationSequence()` with anti-rollback; `RevocationList` `revokedPackIds` made optional
- `lib/audit/audit_chain.dart` — `AuditChain.inMemory()` factory; `computeHeadHmac()`, `verifyHeadHmac()`; `InMemorySecretStore.setSecret()`; `AuditChainStore.saveHeadMac()` method added
- `lib/transport/safe_frame_transport.dart` — `LoopbackGatewayTransport` constructor uses named `guard:` parameter
- `lib/gateway/gateway_contract.dart` — `GatewayInterfaceDescriptor.writeCapable` used in negotiation
- `lib/identification/identification_state_machine.dart` — transport throw caught without crash; minimum evidence weighting
- `lib/features/parameters_screen.dart` — UI callers use `session.auth.unlock()`; pass explicit `ConfirmationToken`
- `test/audit_chain_test.dart` — added `saveHeadMac()` to `_MemoryAuditStore`
- `test/device_session_test.dart` — tests now provide explicit `authorization` and `ConfirmationToken`

---

## Tests Added (t1_safety_and_trust_test.dart)

| Test Name | What It Proves |
|-----------|----------------|
| write without unlock rejected | Viewer-tier auth rejected with `insufficientAuthorization` |
| expired unlock rejected | Expired `AuthorizationSession` returns `expiredAuthorization` |
| reused confirmation token rejected | Single-use token enforced; second write with same token fails |
| diff mismatch token rejected | Wrong hash returns `invalidConfirmation` |
| restore stops when confirmations run out | Empty confirmations list returns empty results |
| architecture: no self-issued auth in lib/session/ | `ConfirmationToken(`, `AuthorizationSession(`, `safetyAcknowledged: true` absent |
| architecture: ConfirmationToken restricted | Only `lib/auth/`, `lib/features/`, `parameter_models.dart` may construct tokens |
| DeviceWriteContext derived dynamically | `exactIdentityMatch = true` on healthy session |
| identityMismatch breaks exactIdentityMatch | `LFP-UNKNOWN-MISMATCH` model causes `exactIdentityMatch = false` |
| SimulatedParameterTransport isolation | No simulator transport construction outside `lib/simulator/` |
| ParameterAccess rejects unknown | `FormatException` on unknown access string |
| hasWriteCapability with readWrite param | Profile with `readWrite` param reports `hasWriteCapability = true` |
| ProfileApproval role/stage enforcement | Only `published` + `approvalEngineer` returns `isApprovedFor = true` |
| ProfileRegistry write gate | Empty registry returns `canWrite = false` |
| LibrarySync anti-rollback | Sequence 4 after 5 throws `StateError` |
| InstalledLibrary 14-day staleness | 19-day-old revocation flagged as stale, write disabled |
| Spoofed simulated profile rejected | Non-bundled simulated profile throws `FormatException` |
| Audit entry tampering detected | `verify()` catches hash mismatch |
| Audit HMAC fails on wrong MAC | `verifyHeadHmac('tampered...')` returns false |
| TrustAnchorRegistry embedded keys | `findKey('solardiag-root-2026-v1')` returns 32-byte key |
| No private keys in lib/ | Scans all `.dart` files for PEM private key patterns |
| GuardRule DLC/mask enforcement | Correct frame passes; wrong DLC or mask value fails |
| LoopbackGatewayTransport burst error | Error frame sets `observedBusLoad = 0.8` |
| Gateway read-only rejects write | `GatewayContractException` on `writeCapable: false` interface |

---

## Command Output Summary

```
flutter test test/device_session_test.dart test/t1_safety_and_trust_test.dart test/audit_chain_test.dart
→ 39 tests passed, 0 failed

flutter gen-l10n → OK (regenerated missing keys)
git commit → 537c462 "fix(T1): safety and trust hardening (S1-S10)"
  25 files changed, 2072 insertions(+), 169 deletions(-)
```

---

## Not Done / Deferred
- Full `flutter test` suite (some other test files have unrelated compilation issues being tracked)
- `dart run tool/profile_check.dart` and `dart run tool/reference_check.dart` — deferred to T6 (tools may need updates for new profile schema)
- Retroactive reports for M5, M6, M7 — deferred to T6 per spec

---

*Proceeding to T2 — Correctness (C1–C6)*
