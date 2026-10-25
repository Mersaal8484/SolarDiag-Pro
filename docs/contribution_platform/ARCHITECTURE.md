# Contribution platform architecture

Implemented locally: deterministic client redaction, granular consent,
`.sdcontrib` packaging, integrity and mock installation signatures, offline
queue/retry/withdrawal, lifecycle gates with separation of duties, mock portal,
an append-only rewards ledger, configuration-driven entitlements, mock-signed
library packs, revocations, downgrade/expiry checks, beta/stable delivery
metadata, delta-base checks, last-known-good cache, and retention of one
previous verified pack.

The future service boundary is specified in [openapi.yaml](openapi.yaml). It
defines ingestion, quarantine, triage, analyst findings, approval, signing,
distribution, revocations, and offline entitlement retrieval. A contract test
compares every `operationId` with the typed in-memory mock portal interface.
The contract is not evidence that any endpoint has been deployed.

The server-side role and evidence gates are specified in
[APPROVAL_POLICY.md](APPROVAL_POLICY.md). They complement the local lifecycle
model and cannot be enforced by an untrusted client alone.

There is no production backend. Ingestion, quarantine re-scan, reviewer console, durable audit service, KMS/HSM signing, distribution CDN, account identity, residency controls, and deletion orchestration remain infrastructure work.

The previous verified library pack is retained for an explicit recovery
workflow only. The client does not automatically roll back or silently retry a
write. Reward points and entitlement state have no path into write
authorization or any safety gate. Safety-critical visibility is fail-open for
display while write authorization remains fail-closed.

`MockSigner` uses HMAC-SHA256 for deterministic local contract tests. It is not an asymmetric production signature and must be replaced by a public-key verification scheme whose private keys remain in KMS/HSM.
