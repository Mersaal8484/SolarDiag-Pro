import 'package:flutter/material.dart';

import 'value_unit_formatter.dart';

enum DigitPreference { western, arabicIndic }

class DesignPreferences extends ChangeNotifier {
  DigitPreference digits = DigitPreference.western;
  bool workshopMode = false;
  bool outdoorHighContrast = false;
  bool timeAxisLtr = true;
  bool reduceTransparency = false;

  void setDigits(DigitPreference value) {
    if (digits == value) return;
    digits = value;
    notifyListeners();
  }

  void setWorkshopMode(bool value) {
    if (workshopMode == value) return;
    workshopMode = value;
    notifyListeners();
  }

  void setOutdoorHighContrast(bool value) {
    if (outdoorHighContrast == value) return;
    outdoorHighContrast = value;
    notifyListeners();
  }

  void setTimeAxisLtr(bool value) {
    if (timeAxisLtr == value) return;
    timeAxisLtr = value;
    notifyListeners();
  }

  void setReduceTransparency(bool value) {
    if (reduceTransparency == value) return;
    reduceTransparency = value;
    notifyListeners();
  }
}

class DesignPreferenceScope extends InheritedNotifier<DesignPreferences> {
  const DesignPreferenceScope({
    required DesignPreferences preferences,
    required super.child,
    super.key,
  }) : super(notifier: preferences);
  static DesignPreferences of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesignPreferenceScope>()!
      .notifier!;
  static DesignPreferences? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesignPreferenceScope>()
      ?.notifier;
}

String localizedDigits(Object value, DigitPreference preference) {
  return ValueUnitFormatter(
    useArabicIndicDigits: preference == DigitPreference.arabicIndic,
  ).localizeDigits(value.toString());
}

String localizedNumber(
  BuildContext context,
  num value, {
  int fractionDigits = 0,
}) => _valueFormatter(context).number(
  value,
  fractionDigits: fractionDigits,
);

String localizedValueWithUnit(
  BuildContext context,
  num value, {
  required EngineeringUnit unit,
  int? fractionDigits,
  bool isolate = true,
}) {
  final formatter = _valueFormatter(context);
  final localizations = AppLocalizations.of(context);
  final formattedNumber = formatter.number(
    value,
    unit: unit,
    fractionDigits: fractionDigits,
  );
  final localized = switch (unit) {
    EngineeringUnit.cycles
        when value == value.roundToDouble() =>
      localizations.cycleValue(value.round(), formattedNumber),
    EngineeringUnit.frames
        when value == value.roundToDouble() =>
      localizations.frameValue(value.round(), formattedNumber),
    EngineeringUnit.samples
        when value == value.roundToDouble() =>
      localizations.sampleValue(value.round(), formattedNumber),
    _ => formatter.format(
      value,
      unit: unit,
      unitLabel: localizedUnitLabel(localizations, unit),
      fractionDigits: fractionDigits,
    ),
  };
  return isolate ? '\u2066$localized\u2069' : localized;
}

String localizedMeasurement(
  BuildContext context,
  num value,
  String? unit, {
  int? fractionDigits,
  bool isolate = true,
}) {
  final parsedUnit = ValueUnitFormatter.fromSymbol(unit);
  if (parsedUnit != EngineeringUnit.none || unit == null || unit.isEmpty) {
    return localizedValueWithUnit(
      context,
      value,
      unit: parsedUnit,
      fractionDigits: fractionDigits,
      isolate: isolate,
    );
  }
  final formatted = localizedValueWithUnit(
    context,
    value,
    unit: EngineeringUnit.none,
    fractionDigits: fractionDigits,
    isolate: false,
  );
  final joined = '$formatted $unit';
  return isolate ? '\u2066$joined\u2069' : joined;
}

ValueUnitFormatter _valueFormatter(BuildContext context) {
  final preference = DesignPreferenceScope.maybeOf(context)?.digits;
  return ValueUnitFormatter(
    useArabicIndicDigits: preference == DigitPreference.arabicIndic,
  );
}

String localizedUnitLabel(
  AppLocalizations localizations,
  EngineeringUnit unit,
) => switch (unit) {
  EngineeringUnit.none || EngineeringUnit.count => '',
  EngineeringUnit.volts => localizations.voltageUnit,
  EngineeringUnit.amps => localizations.unitAmpere,
  EngineeringUnit.watts => localizations.unitWatt,
  EngineeringUnit.percent => localizations.unitPercent,
  EngineeringUnit.celsius => localizations.unitCelsius,
  EngineeringUnit.millivolts => localizations.unitMillivolt,
  EngineeringUnit.milliseconds => localizations.unitMillisecond,
  EngineeringUnit.seconds => localizations.unitSecond,
  EngineeringUnit.hertz => localizations.unitHertz,
  EngineeringUnit.cycles => localizations.unitCycle,
  EngineeringUnit.frames => localizations.unitFrame,
  EngineeringUnit.samples => localizations.unitSample,
};

class TechnicalText extends StatelessWidget {
  const TechnicalText(this.data, {super.key, this.style});
  final String data;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      '\u2066$data\u2069',
      style: const TextStyle(fontFamily: 'JetBrains Mono').merge(style),
    ),
  );
}
