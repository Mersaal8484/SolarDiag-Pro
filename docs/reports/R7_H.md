# Round 7 - Batch H

- H1 files: `platform_api.dart`, `mock_portal.dart`, `openapi.yaml`, and
  contribution architecture/policy docs.
- Decision: 12 OpenAPI `operationId` values exactly match the typed mock API;
  the contract test uses a minimal deterministic reader, so no YAML dependency.
- H2 files: `reward_ledger.dart` and `r7_h_contribution_platform_test.dart`.
- Decision: verified-value weights ignore volume; duplicates earn 0, false data
  deducts points, daily caps rate-limit awards, and SHA-256 links every entry.
- Rewards have no import or call path to authorization, transport, or writes.
- H3 files: `config/entitlements.json`, `entitlements.dart`, `pubspec.yaml`,
  `signed_tokens.dart`, and entitlement tests.
- Decision: free/paid boundaries come from JSON; four mandatory safety features
  remain visible without a token and with an expired token.
- H4 files: `signed_tokens.dart` and `contribution_platform_test.dart`.
- Decision: beta/stable and delta-base metadata are signed; updates retain one
  previous verified pack. No automatic rollback or silent retry was added.
- Existing downgrade, expiry, revocation, and wrong-key tests were not copied.
- H5: 7 seeded sensitive classes plus 14 hex/base64 variants are checked both
  after redaction and in the final package encoding.
- Grep: 12 OpenAPI operations, 12 contract identifiers, 1 API mock implementer,
  2 retained-store implementers; legacy stores keep the base interface.
- Signature review: every new public API has a direct lib/test call site.
- Fixtures were checked against package/redaction parsers and JSON schemas.
- Architecture scan patterns were checked; ARB parity is unchanged (no UI key).
- Uncertainty: OpenAPI is statically inspected, not parsed by a full validator.
- Owner verification exposed two redesign defects: an unbounded dashboard
  `Spacer` and a missing local `Material` below `PrecisionCanvas`; both fixed.
- Owner: contribution 20/20, T1 26/26, R5 A0 6/6, and R5 safety 17/17 passed; dedicated H/analyzer output was not supplied.
- NOT RUN by Codex: formatter, analyzer, tests, generators, goldens, or build.
