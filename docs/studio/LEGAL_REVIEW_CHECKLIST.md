# Protocol Discovery Studio — legal and safety release gate

Version 2.0 — mandatory before a Studio draft can be proposed for publication.
This is an engineering control, not legal advice. The named legal reviewer must
confirm the rules that apply in every target market.

## Automatic blockers

The domain `StudioReleaseGate` blocks a publication request when offline
validation fails, legal review is incomplete, NDA material is present, or the
result has not been validated on authorized physical hardware. Passing this
gate does not make a draft trusted: production signing and the normal profile
approval process remain separate.

## Authorization and lawful intake

- [ ] The investigator owns the equipment or has written authorization that
  identifies the hardware, interfaces, observation period, and permitted acts.
- [ ] Contract, warranty, EULA, service terms, and applicable access-control
  restrictions have been reviewed.
- [ ] No authentication secret, encryption key, secure boot, or technical
  protection measure was bypassed.
- [ ] Encrypted or cryptographically signed vendor traffic is classified as
  protected/unknown and left uninterpreted; it is not decrypted, forged, or
  used to derive a sendable payload.
- [ ] Acquisition was passive. No captured frame, hypothesis, or unverified
  payload was transmitted to live hardware.

## Target-market review

- [ ] Saudi Arabia: counsel reviewed applicable copyright, trade-secret,
  anti-cybercrime, privacy, import/export, and product-safety requirements.
- [ ] European Economic Area: counsel reviewed software interoperability rules,
  including Directive 2009/24/EC Article 6, database rights, GDPR, radio/EMC,
  and product-safety obligations where applicable.
- [ ] United States: counsel reviewed copyright and DMCA 17 U.S.C. §1201,
  applicable exemptions, CFAA/access authorization, trade-secret, privacy, FCC,
  and product-safety requirements.
- [ ] Every additional distribution market has a named reviewer and a recorded
  decision; uncertainty blocks publication.

## NDA, confidentiality, and clean-room controls

- [ ] NDA-derived material is marked `containsNdaMaterial: true` and excluded
  from shareable `.sdcap`, research bundles, contributions, logs, and commits.
- [ ] No proprietary firmware, binaries, credentials, or restricted manuals are
  copied into the repository.
- [ ] Observers who document behavior are separated from implementers whenever
  a clean-room process is required; inputs and hand-off records are retained.
- [ ] Every external source is in `docs/research/references.json` with exact
  commit/version, retrieval date, SPDX license, scope, maintenance observation,
  obligations, and derived artifacts.
- [ ] `THIRD_PARTY_NOTICES.md` is regenerated and passes `reference_check`.

## Safety, provenance, and publication hygiene

- [ ] Replay Lock is visible and enforced in the domain; hypotheses are data,
  never transmission instructions.
- [ ] The exported profile is schema v2, `status: studio-draft`, read-only,
  unsigned, and rejected by technician mode.
- [ ] Manufacturer identity and every decoded field have capture evidence and
  authorized physical-hardware validation.
- [ ] Device serials, MAC/IP addresses, location, technician identity, customer
  data, and secrets are removed or included only with explicit consent.
- [ ] The target market's data-protection rules and retention/deletion duties
  have been reviewed for captures, metadata, and contributor records.
- [ ] Generated files, raw captures, archives, build outputs, and temporary
  artifacts are excluded from commits unless a reviewer explicitly approves a
  minimal redacted fixture.
- [ ] A discovered safety or security flaw follows responsible disclosure and
  remains embargoed for the vendor-agreed period.

## Sign-off

| Role | Reviewer | Market / organization | Date | Decision |
|---|---|---|---|---|
| Legal / compliance | | | | Blocked / Approved |
| Safety engineering | | | | Blocked / Approved |
| Repository maintainer | | | | Blocked / Approved |

Record the completed checklist with the proposed profile's immutable evidence
bundle hash. A blank, expired, or scope-mismatched sign-off means blocked.
