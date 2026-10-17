# Battery diagnostics

Diagnostics consume only reported snapshot fields and raw alarm codes. Cell-balance findings expose the measured minimum, maximum, delta, and cell count as evidence. Thermal findings remain unavailable when the device did not report temperature.

State of health is deliberately nullable. The current engine returns `SOH_NOT_REPORTED_OR_DERIVABLE`; it does not estimate SOH from voltage, state of charge, or a short observation window.

Known alarm codes map through the active profile's bilingual fault dictionary while retaining the raw code and suggested checks. Unknown vendor bits remain raw, carry low confidence, and are never assigned a guessed meaning.

Round 2 adds per-cell quality, standard deviation and persistent outliers; labeled temperature distribution and gradient; parallel-bank current/SOC/address/role checks; snapshot comparison; and capacity trends with explicit method notes and uncertainty. None of these calculations silently becomes an SOH estimate.

Thresholds are explicit configuration values in `DiagnosticThresholds`; real profiles will eventually override them only when backed by verified manufacturer evidence.
