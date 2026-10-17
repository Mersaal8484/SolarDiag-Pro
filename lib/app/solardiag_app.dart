import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../config/feature_flags.dart';
import '../simulator/simulation_scenario.dart';
import '../features/advanced_diagnostics.dart';
import '../features/design_lab.dart';
import '../features/workspace_shell.dart';
import 'theme.dart';

class SolarDiagApp extends StatefulWidget {
  const SolarDiagApp({super.key, this.flags = const FeatureFlags()});
  final FeatureFlags flags;
  @override
  State<SolarDiagApp> createState() => _SolarDiagAppState();
}

class _SolarDiagAppState extends State<SolarDiagApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;
  bool _highContrast = false;
  SimulationScenario _scenario = SimulationScenario.communicationFaults;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SolarDiag Pro',
    locale: _locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    themeMode: _themeMode,
    theme: solarTheme(
      brightness: Brightness.light,
      highContrast: _highContrast,
    ),
    darkTheme: solarTheme(
      brightness: Brightness.dark,
      highContrast: _highContrast,
    ),
    home: Builder(
      builder: (context) {
        final snapshot = ScenarioFactory.create(
          _scenario,
          tick: _scenario == SimulationScenario.communicationFaults ? 2 : 0,
        ).snapshot;
        return WorkspaceShell(
          snapshot: snapshot,
          scenario: _scenario,
          onScenarioChanged: (scenario) => setState(() => _scenario = scenario),
          onToggleLocale: () => setState(
            () => _locale = _locale.languageCode == 'en'
                ? const Locale('ar')
                : const Locale('en'),
          ),
          onToggleTheme: () => setState(
            () => _themeMode = _themeMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light,
          ),
          onToggleContrast: () =>
              setState(() => _highContrast = !_highContrast),
          onOpenDesignLab: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const DesignLab())),
          onOpenDiagnostics: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AdvancedDiagnosticsScreen(snapshot: snapshot),
            ),
          ),
          studioEnabled: widget.flags.studioEnabled,
          contributionsEnabled: widget.flags.contributionsEnabled,
        );
      },
    ),
  );
}
