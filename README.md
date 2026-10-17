# SolarDiag Pro

Professional, safety-first diagnostics for solar inverters and lithium battery systems.

> Read everything. Change only what is proven safe.

This repository contains a runnable, safety-first Flutter vertical slice:
deterministic BMS simulation, a live device-session layer, diagnostics,
verified parameter writes and backup restore, inverter–battery compatibility,
local SQLite history, integrity-checked JSON/PDF engineering reports, Protocol
Discovery Studio, and a reviewed contribution-platform mock. It does **not**
claim support for real hardware or provide a production cloud backend.

```powershell
flutter test
flutter run -d windows
```

Diagnostic data remains local. Session evidence and parameter backups are
stored in SQLite under the platform application-support directory. Reports are
written to `SolarDiag Reports` under the platform application-documents
directory. Simulator reports are watermarked on every PDF page and marked
`simulated: true` in JSON.

The adaptive workspace includes a computed six-destination home, live battery
and simulated-inverter diagnostics, link evidence, device library, diagnostic
history, gateway state and verified simulator parameter workflows. First run
uses a locally persisted three-step read-only-first onboarding flow. Major
screens also expose named routes for desktop and Android deep links.

Studio and contributions are disabled by default through feature flags. See `docs/FINAL_GAP_REPORT.md` and the generated `docs/CAPABILITY_MATRIX.md` for honest scope and verification status.
