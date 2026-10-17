# Inverter–battery integration

The integration engine compares verified or reported evidence only: charge voltage, low-voltage cutoff, charge/discharge current, chemistry, and shared communication protocols. Missing inputs produce `unknown`, never a compatibility claim.

Link diagnostics evaluate message delivery, timeouts, CRC failures, and SOC consistency over an explicit observation window. Thresholds are configuration values and every result carries its evidence.

This module is advisory and read-only. It contains no method that changes inverter or battery configuration and will never reconfigure both devices to force compatibility.
