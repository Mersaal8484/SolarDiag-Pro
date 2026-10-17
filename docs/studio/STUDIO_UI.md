# Studio workspace

The engineering workspace implements ten sections: Sessions, Capture, Frame Explorer, Analysis, Differential, Hypotheses, Profile Builder, Mapping Editor, Validation, and Export.

The end-to-end demo uses a clearly synthetic CAN capture. Analysis is performed by the same Studio core used in tests. Findings surface state, confidence, and evidence. Export always emits `studio-draft`, disables technician-mode loading and write capability, and cannot publish.

`studio.enabled` is represented by `FeatureFlags.studioEnabled` and defaults to false. The Studio destination is absent unless explicitly enabled. Replay Lock is displayed persistently in the workspace.

Hardware capture, production persistence, graphical bitfield editing, and approved profile publication remain unimplemented.
