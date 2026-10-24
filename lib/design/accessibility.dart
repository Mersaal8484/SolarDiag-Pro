import 'package:flutter/material.dart';

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
  final input = value.toString();
  if (preference == DigitPreference.western) return input;
  const western = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  return input.split('').map((character) {
    final index = western.indexOf(character);
    return index < 0 ? character : arabic[index];
  }).join();
}

String localizedNumber(
  BuildContext context,
  num value, {
  int fractionDigits = 0,
}) => localizedDigits(
  value.toStringAsFixed(fractionDigits),
  DesignPreferenceScope.maybeOf(context)?.digits ?? DigitPreference.western,
);

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
