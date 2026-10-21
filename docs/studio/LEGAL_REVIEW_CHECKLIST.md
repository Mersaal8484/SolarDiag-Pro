# Protocol Discovery Studio — Legal and Safety Review Checklist

**Document Version:** 1.0  
**Authority:** SolarDiag Pro Architecture and Engineering Safety Policies  
**Status:** Mandatory Pre-Release / Pre-Publication Checklist

Before any capture session, protocol draft profile, or community contribution is published or advanced beyond `studio-draft` status, this checklist must be completed and signed off by the responsible parties.

---

## 1. Authorization and Lawful Intake

- [ ] **Equipment Ownership / Written Consent:** The hardware, battery system, and communication buses analyzed were either directly owned by the investigator or tested under explicit written authorization specifying authorized interfaces, observation window, and permissible methods.
- [ ] **Contract and Warranty Review:** Testing complied with all applicable service agreements, warranties, end-user license agreements (EULAs), and terms of service.
- [ ] **No Access Control Circumvention:** The reverse-engineering activities did not circumvent technical protection measures (TPMs), encryption keys, or authentication barriers prohibited by applicable anti-circumvention laws (e.g., DMCA § 1201 or local equivalents).
- [ ] **Passive Observation Only:** Analysis was conducted via passive listening on the physical bus. No unauthorized, fuzzing, or unverified frame injection was transmitted on a live energy storage bus.

---

## 2. Non-Disclosure and Confidentiality Screening

- [ ] **NDA Material Flagging:** Any trace, capture, register map, or documentation derived from non-public non-disclosure agreements is explicitly flagged with `containsNdaMaterial: true`.
- [ ] **Export Gate Enforcement:** Verified that all NDA-flagged materials are barred from `.sdcap` shareable bundles, community contribution packages, and public repository commits.
- [ ] **No Proprietary Firmware Extraction:** No proprietary binaries or firmware dumps subject to redistribution restrictions are included in repository commits or capture files.

---

## 3. Clean-Room Methodology and Provenance

- [ ] **Evidence Separation:** Observations, timings, and byte patterns are documented strictly from independent empirical captures or publicly documented manufacturer specifications.
- [ ] **Reference Registry Compliance:** All external references (open-source tools, publicly available manuals) are recorded in `docs/research/references.json` with exact URLs, retrieval dates, SPDX license IDs, and obligations.
- [ ] **Third-Party Copyright Attribution:** Third-party notices are generated and checked against `THIRD_PARTY_NOTICES.md` without omissions.
- [ ] **No Substantial Source Copying:** No source code or register descriptions from proprietary software have been copied verbatim into draft profiles.

---

## 4. Physical Safety and Replay Lock Verification

- [ ] **Replay Lock Active:** Replay Lock remains permanently enabled in the domain and UI layers. Captured frames cannot be loaded into transmission queues or replayed to real hardware.
- [ ] **Draft Profile Quarantine:** The generated profile is marked `category: "studio-draft"`, remains strictly read-only, and cannot be loaded in technician mode.
- [ ] **Parameter Write Guard:** Write and calibration capabilities are disabled (`VerificationStatus.unverified` or `VerificationStatus.simulated`). No write parameters exist without verified hardware sign-off and safety limits.
- [ ] **Safe Default Limits:** All voltage, current, and temperature limits in the draft profile align with conservative LFP/NMC cell safety boundaries.

---

## 5. Privacy, PII, and Telemetry Redaction

- [ ] **Network & Device Redaction:** Network MAC addresses, local IP subnets, device serial numbers, and geographic location coordinates have been verified redacted or sanitized.
- [ ] **Technician Identity:** Contributor signatures and technician identifiers use pseudonymous or consent-verified identifiers.
- [ ] **Consent Verification:** Explicit contributor consent records accompany any data destined for upstream contribution platforms.

---

## 6. Vulnerability and Responsible Disclosure

- [ ] **Safety Hazard Assessment:** If protocol analysis identified critical safety flaws (e.g., unauthenticated remote shutdown, unvalidated high-current commands), a responsible disclosure ticket has been initiated with the manufacturer.
- [ ] **Embargo Management:** Public profile draft release is held until the responsible disclosure coordination window (minimum 90 days or vendor mutual agreement) has expired.

---

## 7. Sign-off Records

| Role | Reviewer Name | Organization / Affiliation | Date | Status (Approved / Blocked) |
|---|---|---|---|---|
| Legal / Compliance | | | | |
| Lead Safety Engineer | | | | |
| Repository Maintainer | | | | |
