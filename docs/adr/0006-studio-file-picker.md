# ADR 0006: Native capture-file selection

## Status

Accepted.

## Context

The Protocol Discovery Studio must import user-selected capture files on
Android, Windows and the other Flutter targets. Capture bytes remain local and
must not be uploaded or interpreted by a remote service.

## Decision

Use `file_picker` 13.x solely to open the platform file chooser and read one
selected capture into memory. The Studio limits the selectable extensions to
`.sdcap`, `.log`, `.candump`, `.csv`, `.slcan`, and `.txt`. Format detection and
parsing remain in SolarDiag code, and malformed lines are reported without
silent repair. `pcap`, `pcapng`, and Vector ASC remain unsupported.

Version 13.1.0 was selected because it supports the project's Dart SDK, uses
the federated picker API, and resolves with the Win32 6 dependency required by
`wakelock_plus`. The package is MIT licensed. No network permission or
analytics is introduced.

## Consequences

- Native chooser behavior varies by platform.
- Large-file streaming is handled by the Studio analysis layer after import;
  the picker itself is not a parser or trust boundary.
- Cancellation produces no state change.
