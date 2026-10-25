# Contribution approval policy and role matrix

## Scope

This policy defines the future server-side approval contract. The Flutter
client and its in-memory mock portal model the transitions for local testing;
they do not confer real-world approval authority.

## Roles

| Role | May do | Must not do |
|---|---|---|
| Contributor | Create, preview, submit, and withdraw own redacted contribution | Approve, sign, publish, or alter another contributor's record |
| System | Run sanitization and quarantine checks | Act as a human reviewer or bypass an evidence gate |
| Analyst | Triage, analyse evidence, and mark a candidate | Approve a profile they analysed or publish a pack |
| Approval engineer | Validate evidence and perform Safety Review | Approve their own analysis or publish a pack |
| Administrator | Sign/publish only after all required records are present; revoke/deprecate | Replace safety evidence or waive separation of duties |

All production identities, roles, and events must be authenticated and stored
server-side. The client displays signed outcomes and cannot grant itself a
role.

## Lifecycle gates

`Draft → Submitted → Sanitized → Triage → Analysis → Candidate → Validation`

- A read-only profile may proceed from `Validation` to `Approved` only after
  documented evidence is accepted.
- A profile with write or calibration capability must pass `Safety Review`
  before `Approved`.
- `Approved → Signed → Published` requires an administrator action after the
  preceding records are immutable and complete.
- `Declined` requires a reason before approval. `Deprecated` and `Revoked`
  require an administrator, a published profile, and a reason.

## Separation of duties

One authenticated person may not serve in multiple human review roles for the
same contribution. In particular, the analyst and approval engineer for a
write/calibration profile must be different people. The production service
must enforce this rule; client-side checks are only defence in depth.

## Required evidence before publication

| Capability | Minimum evidence |
|---|---|
| Identify / live telemetry | Provenance, identity/firmware match, offline replay and read-only hardware report |
| Configuration read | Above plus scaling/range evidence and parser tests |
| Write / calibration | Above plus independent Safety Review, authorized real-hardware evidence, documented manufacturer procedure, dependency/limit checks, and risk assessment |

No contribution, capture, Studio draft, or community source can publish a
write command automatically. A revocation event takes priority over a
published state and must disable that capability in every client on receipt of
a valid signed revocation list.

## API relationship

The generic transition endpoint and the explicit quarantine, triage, analyst,
approval, and signing endpoints are defined in [openapi.yaml](openapi.yaml).
They must return `403` for a role/evidence/separation-of-duties failure and
`409` for an invalid state transition. They are a future service contract, not
deployed endpoints.
