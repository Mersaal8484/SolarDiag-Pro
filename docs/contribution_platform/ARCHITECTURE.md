# Contribution platform architecture

Implemented locally: deterministic client redaction, granular consent, `.sdcontrib` packaging, integrity and mock installation signatures, offline queue/retry/withdrawal, lifecycle gates with separation of duties, mock portal, mock-signed library packs, revocations, downgrade/expiry checks, last-known-good cache, and offline entitlement validation.

There is no production backend. Ingestion, quarantine re-scan, reviewer console, durable audit service, KMS/HSM signing, distribution CDN, account identity, residency controls, and deletion orchestration remain infrastructure work.

`MockSigner` uses HMAC-SHA256 for deterministic local contract tests. It is not an asymmetric production signature and must be replaced by a public-key verification scheme whose private keys remain in KMS/HSM.
