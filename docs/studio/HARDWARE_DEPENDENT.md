# Hardware-dependent Studio features

Pending hardware: isolated CAN, RS485, RS232 and UART capture, bus-error counters, termination detection, electrical-level warnings, gateway timestamp validation, and sustained million-frame ingestion from a physical device.

Replay Lock already prohibits capture-derived hardware transmission at the domain boundary. No real transport is connected to Studio.

Software-only validation uses deterministic CAN, Modbus RTU and malformed UART
fixtures. These fixtures test ingestion and analysis behavior but are not
evidence that any physical adapter or manufacturer device is supported.
