# Reference registry

The machine-readable authority is `docs/research/references.json`. Run `dart run tool/reference_check.dart` to validate it and regenerate `THIRD_PARTY_NOTICES.md`; CI uses `--check` and fails on stale notices, incomplete metadata, missing derived artifacts, or profile provenance that does not resolve to a registered document.

Open-source protocol implementations are research leads, not trusted device definitions. At intake, record the exact version or commit, SPDX license, maintenance state, stated scope, and actual fields used. Any derived definition is marked `communitySourced`, remains read-only, and cannot enable parameter writes or calibration. Manufacturer documentation and physical validation are required before write capability can be approved.

The four audited public research leads are pinned to full Git commits:
`syssi/esphome-jk-bms`, `syssi/esphome-pipsolar`,
`syssi/esphome-daly-bms`, and `jblance/mpp-solar`. Their licenses and obligations differ;
the registry is authoritative. No upstream source code is copied into SolarDiag
Pro, and availability or recent activity is not an upstream support guarantee.

The FRECON manual is registered as a user-supplied proprietary manufacturer document. The PDF is not committed or redistributed, and its scope is limited to the communication settings and connection checklist stated in the registry. It does not establish register addresses or fault codes.
