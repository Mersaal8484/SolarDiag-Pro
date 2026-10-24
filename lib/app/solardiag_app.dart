import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../audit/audit_chain.dart';
import '../config/feature_flags.dart';
import '../features/advanced_diagnostics.dart';
import '../features/battery_workspace.dart';
import '../features/device_library.dart';
import '../features/design_lab.dart';
import '../features/gateway_screen.dart';
import '../features/inverter_diagnostics_screen.dart';
import '../features/link_screen.dart';
import '../features/onboarding_screen.dart';
import '../features/parameters_screen.dart';
import '../features/session_history_screen.dart';
import '../features/settings_screen.dart';
import '../features/workspace_shell.dart';
import '../design/accessibility.dart';
import '../l10n/generated/app_localizations.dart';
import '../persistence/local_database.dart';
import '../session/device_session.dart';
import '../trust/library_write_reason.dart';
import '../trust/signed_tokens.dart';
import '../trust/trust_anchors.dart';
import 'theme.dart';

class SolarDiagApp extends StatefulWidget {
  const SolarDiagApp({
    super.key,
    this.flags = const FeatureFlags(),
    this.session,
    this.database,
    this.auditSecretStore,
    this.showOnboarding = false,
    this.initialRoute = '/',
  });
  final FeatureFlags flags;
  final DeviceSession? session;
  final LocalDatabase? database;
  final SecretStore? auditSecretStore;
  final bool showOnboarding;
  final String initialRoute;
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
  bool _wakelockEnabled = false;
  late bool _onboardingVisible;
  @override
  void initState() {
    super.initState();
    _ownsDeviceSession = widget.session == null;
    _ownsDatabase = widget.session == null && widget.database != null;
    _deviceSession =
        widget.session ??
        DeviceSession(
          database: widget.database,
          auditSecretStore: widget.auditSecretStore,
        );
    _onboardingVisible = widget.showOnboarding;
    _restoreSettings();
    _deviceSession.setLibraryWriteStatus(
      reason: widget.flags.libraryEnabled
          ? LibraryWriteDisabledReason.libraryMissing
          : null,
      blocksWrites: widget.flags.libraryEnabled,
    );
    if (widget.flags.libraryEnabled) {
      unawaited(_loadOfflineLibrary());
    }
    if (_designPreferences.workshopMode) {
      unawaited(_applyWorkshopMode());
    }
  }

  Future<void> _applyWorkshopMode() async {
    final enabled = _designPreferences.workshopMode;
    if (_wakelockEnabled == enabled) return;
    await WakelockPlus.toggle(enable: enabled);
    _wakelockEnabled = enabled;
  }

  Future<void> _loadOfflineLibrary() async {
    final anchors = TrustAnchorRegistry();
    final now = DateTime.now().toUtc();
    final trustedAnchor = anchors.keys
        .where((key) => key.isValidAt(now))
        .firstOrNull;
    if (trustedAnchor == null) {
      _deviceSession.setLibraryWriteStatus(
        reason: LibraryWriteDisabledReason.noValidTrustAnchor,
        blocksWrites: true,
      );
      return;
    }
    final directory = await getApplicationSupportDirectory();
    final sync = LibrarySync(
      verifier: trustedAnchor.createVerifier(),
      appVersion: 1,
      store: FileLibraryPackStore(
        '${directory.path}${Platform.pathSeparator}library.pack.json',
      ),
    );
    await sync.restoreOffline(now: now);
    final reason = sync.writeDisabledReasonFor(_deviceSession.activeProfileId);
    _deviceSession.setLibraryWriteStatus(
      reason: reason,
      blocksWrites: reason != null,
    );
    if (mounted) setState(() {});
  }

  void _restoreSettings() {
    final database = widget.database;
    if (database == null) return;
    _locale = Locale(database.getSetting('language') ?? 'en');
    _themeMode = ThemeMode.values.firstWhere(
      (value) => value.name == database.getSetting('theme_mode'),
      orElse: () => ThemeMode.light,
    );
    _designPreferences.digits = DigitPreference.values.firstWhere(
      (value) => value.name == database.getSetting('digit_preference'),
      orElse: () => DigitPreference.western,
    );
    _designPreferences.workshopMode = database.getBool('workshop_mode');
    _designPreferences.outdoorHighContrast = database.getBool(
      'outdoor_high_contrast',
    );
    _designPreferences.timeAxisLtr = database.getBool(
      'time_axis_ltr',
      defaultValue: true,
    );
    _designPreferences.reduceTransparency = database.getBool(
      'reduce_transparency',
    );
  }

  void _persistSettings() {
    final database = widget.database;
    if (database == null) return;
    database
      ..setSetting('language', _locale.languageCode)
      ..setSetting('theme_mode', _themeMode.name)
      ..setSetting('digit_preference', _designPreferences.digits.name)
      ..setBool('workshop_mode', _designPreferences.workshopMode)
      ..setBool('outdoor_high_contrast', _designPreferences.outdoorHighContrast)
      ..setBool('time_axis_ltr', _designPreferences.timeAxisLtr)
      ..setBool('reduce_transparency', _designPreferences.reduceTransparency);
  }

  @override
  void dispose() {
    if (_ownsDeviceSession) _deviceSession.dispose();
    if (_ownsDatabase) widget.database!.close();
    if (_wakelockEnabled) unawaited(WakelockPlus.disable());
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
        initialRoute: widget.initialRoute,
        routes: {
          '/battery': (_) => const BatteryWorkspace(),
          '/diagnostics': (_) => const AdvancedDiagnosticsScreen(),
          '/inverter': (_) => const InverterDiagnosticsScreen(),
          '/link': (_) => const LinkScreen(),
          '/library': (_) => DeviceLibraryScreen(
            writeDisabledReason: _deviceSession.libraryWriteDisabledReason,
          ),
          '/history': (_) => const SessionHistoryScreen(),
          '/gateway': (_) => const GatewayScreen(),
          '/parameters': (_) => const ParametersScreen(),
          '/design-lab': (_) => const DesignLab(),
          '/settings': (_) => SettingsScreen(
            locale: _locale,
            themeMode: _themeMode,
            onLocaleChanged: (value) {
              setState(() => _locale = value);
              _persistSettings();
            },
            onThemeModeChanged: (value) {
              setState(() => _themeMode = value);
              _persistSettings();
            },
            onPreferencesChanged: () {
              setState(() {});
              _persistSettings();
              unawaited(_applyWorkshopMode());
            },
          ),
        },
        theme: solarTheme(
          brightness: Brightness.light,
          highContrast: _highContrast || _designPreferences.outdoorHighContrast,
          workshop: _designPreferences.workshopMode,
          reduceTransparency: _designPreferences.reduceTransparency,
        ),
        darkTheme: solarTheme(
          brightness: Brightness.dark,
          highContrast: _highContrast || _designPreferences.outdoorHighContrast,
          workshop: _designPreferences.workshopMode,
          reduceTransparency: _designPreferences.reduceTransparency,
        ),
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          if (_deviceSession.auditIntegrityAvailable) return content;
          final s = AppLocalizations.of(context);
          return Column(
            children: [
              MaterialBanner(
                content: Text(s.auditKeyUnavailable),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: Text(s.physicalWriteLocked),
                  ),
                ],
              ),
              Expanded(child: content),
            ],
          );
        },
        home: Builder(
          builder: (context) {
            if (_onboardingVisible) {
              return OnboardingScreen(
                onComplete: () {
                  widget.database?.setBool('onboarding_complete', true);
                  setState(() => _onboardingVisible = false);
                },
              );
            }
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
              onOpenDesignLab: () =>
                  Navigator.of(context).pushNamed('/design-lab'),
              onOpenDiagnostics: () =>
                  Navigator.of(context).pushNamed('/diagnostics'),
              onOpenSettings: () =>
                  Navigator.of(context).pushNamed('/settings'),
              studioEnabled: widget.flags.studioEnabled,
              contributionsEnabled: widget.flags.contributionsEnabled,
              libraryWriteDisabledReason:
                  _deviceSession.libraryWriteDisabledReason,
            );
          },
        ),
      ),
    ),
  );
}
