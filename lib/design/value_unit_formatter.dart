enum EngineeringUnit {
  none,
  volts,
  amps,
  watts,
  percent,
  celsius,
  millivolts,
  milliseconds,
  seconds,
  hertz,
  cycles,
  frames,
  samples,
  count,
}

/// Pure-Dart formatter for localized engineering values and units.
class ValueUnitFormatter {
  const ValueUnitFormatter({
    this.useArabicIndicDigits = false,
  });

  final bool useArabicIndicDigits;

  String number(
    num value, {
    EngineeringUnit unit = EngineeringUnit.none,
    int? fractionDigits,
  }) {
    final digits =
        fractionDigits ?? _defaultPrecision(unit, value);
    return localizeDigits(value.toStringAsFixed(digits));
  }

  String format(
    num value, {
    EngineeringUnit unit = EngineeringUnit.none,
    String unitLabel = '',
    int? fractionDigits,
    bool isolate = false,
  }) {
    final formatted = number(
      value,
      unit: unit,
      fractionDigits: fractionDigits,
    );
    final unitText = unitLabel.isEmpty ? _unitSymbol(unit) : unitLabel;
    final joined = unitText.isEmpty ? formatted : '$formatted $unitText';
    return isolate ? '\u2066$joined\u2069' : joined;
  }

  String localizeDigits(String input) {
    if (!useArabicIndicDigits) return input;
    const western = '0123456789';
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    return input.split('').map((character) {
      final index = western.indexOf(character);
      return index < 0 ? character : arabicIndic[index];
    }).join();
  }

  int _defaultPrecision(EngineeringUnit unit, num value) => switch (unit) {
    EngineeringUnit.count ||
    EngineeringUnit.cycles ||
    EngineeringUnit.frames ||
    EngineeringUnit.samples ||
    EngineeringUnit.percent => 0,
    EngineeringUnit.volts || EngineeringUnit.amps => 2,
    EngineeringUnit.watts ||
    EngineeringUnit.celsius ||
    EngineeringUnit.millivolts ||
    EngineeringUnit.milliseconds ||
    EngineeringUnit.seconds ||
    EngineeringUnit.hertz => 1,
    EngineeringUnit.none => value == value.roundToDouble() ? 0 : 2,
  };

  String _unitSymbol(EngineeringUnit unit) => switch (unit) {
      EngineeringUnit.none ||
      EngineeringUnit.count ||
      EngineeringUnit.cycles ||
      EngineeringUnit.frames ||
      EngineeringUnit.samples => '',
      EngineeringUnit.volts => 'V',
      EngineeringUnit.amps => 'A',
      EngineeringUnit.watts => 'W',
      EngineeringUnit.percent => '%',
      EngineeringUnit.celsius => '°C',
      EngineeringUnit.millivolts => 'mV',
      EngineeringUnit.milliseconds => 'ms',
      EngineeringUnit.seconds => 's',
      EngineeringUnit.hertz => 'Hz',
    };

  static EngineeringUnit fromSymbol(String? symbol) => switch (symbol) {
    'V' => EngineeringUnit.volts,
    'A' => EngineeringUnit.amps,
    'W' => EngineeringUnit.watts,
    '%' => EngineeringUnit.percent,
    '°C' => EngineeringUnit.celsius,
    'mV' => EngineeringUnit.millivolts,
    'ms' => EngineeringUnit.milliseconds,
    's' => EngineeringUnit.seconds,
    'Hz' => EngineeringUnit.hertz,
    'cycles' => EngineeringUnit.cycles,
    'frames' => EngineeringUnit.frames,
    'samples' => EngineeringUnit.samples,
    _ => EngineeringUnit.none,
  };
}
