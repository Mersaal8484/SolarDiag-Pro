# Device category decision

FRECON PV100/PV200 is currently represented as an `inverter` research target. The
product owner still needs to decide whether solar-pump drives/VFDs should become a
third visible category. Profile v2 deliberately stores category as a non-empty
string, so a later `vfd` category does not require a schema change. No VFD-specific
navigation is exposed before that decision.
