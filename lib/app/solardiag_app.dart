import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../config/feature_flags.dart';
import '../features/advanced_diagnostics.dart';
import '../features/design_lab.dart';
import '../features/workspace_shell.dart';
import '../design/accessibility.dart';
import '../l10n/generated/app_localizations.dart';
import '../persistence/local_database.dart';
import '../session/device_session.dart';
import 'theme.dart';

class SolarDiagApp extends StatefulWidget {
  const SolarDiagApp({
    super.key,
    this.flags = const FeatureFlags(),
    this.session,
    this.database,
  });
  final FeatureFlags flags;
  final DeviceSession? session;
  final LocalDatabase? database;
  @override
  State<SolarDiagApp> createState() => _SolarDiagAppState();
}

class _SolarDiagAppState extends State<SolarDiagApp> {
  final DesignPreferences _designPreferences = DesignPreferences();
  late final DeviceSession _deviceSession;
  late final bool _ownsDeviceSession;
  late final bool _ownsDatabase;
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;
  bool _highContrast = false;
  @override
  void initState() {
    super.initState();
    _ownsDeviceSession = widget.session == null;
    _ownsDatabase = widget.session == null && widget.database != null;
    _deviceSession = widget.session ?? DeviceSession(database: widget.database);
  }

  @override
  void dispose() {
    if (_ownsDeviceSession) _deviceSession.dispose();
    if (_ownsDatabase) widget.database!.close();
    _designPreferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeviceSessionScope(
    session: _deviceSession,
    child: DesignPreferenceScope(
      preferences: _designPreferences,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: _locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: _themeMode,
        theme: solarTheme(
          brightness: Brightness.light,
          highContrast: _highContrast || _designPreferences.outdoorHighContrast,
          workshop: _designPreferences.workshopMode,
        ),
        darkTheme: solarTheme(
          brightness: Brightness.dark,
          highContrast: _highContrast || _designPreferences.outdoorHighContrast,
          workshop: _designPreferences.workshopMode,
        ),
        home: Builder(
          builder: (context) {
            return WorkspaceShell(
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
              onOpenDesignLab: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DesignLab()),
              ),
              onOpenDiagnostics: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdvancedDiagnosticsScreen(),
                ),
              ),
              studioEnabled: widget.flags.studioEnabled,
              contributionsEnabled: widget.flags.contributionsEnabled,
            );
          },
        ),
      ),
    ),
  );
}
