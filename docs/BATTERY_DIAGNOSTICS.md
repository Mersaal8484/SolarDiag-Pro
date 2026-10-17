# Battery diagnostics

Diagnostics consume only reported snapshot fields and raw alarm codes. Cell-balance findings expose the measured minimum, maximum, delta, and cell count as evidence. Thermal findings remain unavailable when the device did not report temperature.

State of health is deliberately nullable. The current engine returns `SOH_NOT_REPORTED_OR_DERIVABLE`; it does not estimate SOH from voltage, state of charge, or a short observation window.

Known alarm codes map to localized meanings while retaining the raw code. Unknown vendor bits remain raw, carry low confidence, and are never assigned a guessed meaning.

Thresholds are explicit configuration values in `DiagnosticThresholds`; real profiles will eventually override them only when backed by verified manufacturer evidence.
