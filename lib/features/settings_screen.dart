import 'package:flutter/material.dart';

import '../design/accessibility.dart';
import '../design/components.dart';
import '../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    required this.onPreferencesChanged,
    super.key,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onPreferencesChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final preferences = DesignPreferenceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SolarLabeledPanel(
            title: s.language,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'en', label: Text(s.english)),
                ButtonSegment(value: 'ar', label: Text(s.arabic)),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (value) =>
                  onLocaleChanged(Locale(value.single)),
            ),
          ),
          const SizedBox(height: 16),
          SolarLabeledPanel(
            title: s.themeSetting,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(s.lightTheme),
                ),
                ButtonSegment(value: ThemeMode.dark, label: Text(s.darkTheme)),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(s.systemTheme),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (value) => onThemeModeChanged(value.single),
            ),
          ),
          const SizedBox(height: 16),
          SolarLabeledPanel(
            title: s.digitPreference,
            child: SegmentedButton<DigitPreference>(
              segments: [
                ButtonSegment(
                  value: DigitPreference.western,
                  label: Text(s.westernDigits),
                ),
                ButtonSegment(
                  value: DigitPreference.arabicIndic,
                  label: Text(s.arabicIndicDigits),
                ),
              ],
              selected: {preferences.digits},
              onSelectionChanged: (value) {
                preferences.setDigits(value.single);
                onPreferencesChanged();
              },
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: preferences.workshopMode,
            title: Text(s.workshopMode),
            subtitle: Text(s.workshopModeDescription),
            onChanged: (value) {
              preferences.setWorkshopMode(value);
              onPreferencesChanged();
            },
          ),
          SwitchListTile(
            value: preferences.outdoorHighContrast,
            title: Text(s.outdoorMode),
            subtitle: Text(s.outdoorModeDescription),
            onChanged: (value) {
              preferences.setOutdoorHighContrast(value);
              onPreferencesChanged();
            },
          ),
          SwitchListTile(
            value: preferences.timeAxisLtr,
            title: Text(s.timeAxisDirection),
            subtitle: Text(s.timeAxisDirectionDescription),
            onChanged: (value) {
              preferences.setTimeAxisLtr(value);
              onPreferencesChanged();
            },
          ),
          SwitchListTile(
            value: preferences.reduceTransparency,
            title: Text(s.reduceTransparency),
            subtitle: Text(s.reduceTransparencyDescription),
            onChanged: (value) {
              preferences.setReduceTransparency(value);
              onPreferencesChanged();
            },
          ),
        ],
      ),
    );
  }
}
