# `.sdcontrib` specification

Schema version 2 is a JSON contract-test container with manifest, redacted
payload, SHA-256 content hash, and installation HMAC signature. The manifest
contains a pseudonymous contributor id, the explicitly consented categories,
consent record, redaction report, and a mandatory `synthetic: false` marker.

Synthetic data is rejected before packaging. Production must replace the mock
HMAC mechanism with an approved installation-key design and server-side
signature verification. The future HTTP envelope is defined in
[openapi.yaml](openapi.yaml).
