# Privacy and consent

Collected only with per-submission consent: manufacturer/model/firmware, interface settings, read requests/responses, diagnostic logs, authorized samples, and engineer notes.

Credentials, service keys, serial numbers, MAC/IP data, SSIDs, hostnames, coordinates, customer/site names, and personal identifiers are not collected by default. The client redacts known patterns before packaging and exposes a redaction report. Production must perform a second server-side scan and quarantine suspicious submissions.

Consent is granular, versioned, revocable, and withdrawal-capable. Each category is omitted unless it is both populated and explicitly consented, and the sharing manifest is derived from the resulting package.

Aliases use a session-specific salt and 128-bit SHA-256-derived labels. This reduces casual linkage but does **not** guarantee irreversible anonymization: repeated values inside one session remain linkable, distinctive telemetry can identify an installation, and a party possessing auxiliary data may re-identify a device or site. Every contribution therefore remains flagged for legal review. A residual detector blocks submission and requires manual review instead of guessing when sensitive material remains.

Retention period, Saudi PDPL/GDPR legal basis, data residency, controller/processor roles, irreversible anonymization boundary, contributor license terms, and data-subject request operations require qualified legal review before rollout.
