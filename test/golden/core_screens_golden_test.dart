import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/design/accessibility.dart';
import 'package:solardiag_pro/design/components.dart';
import 'package:solardiag_pro/features/battery_workspace.dart';
import 'package:solardiag_pro/features/gateway_screen.dart';
import 'package:solardiag_pro/features/inverter_diagnostics_screen.dart';
import 'package:solardiag_pro/features/link_screen.dart';
import 'package:solardiag_pro/features/onboarding_screen.dart';
import 'package:solardiag_pro/features/parameters_screen.dart';
import 'package:solardiag_pro/features/settings_screen.dart';
import 'package:solardiag_pro/features/session_history_screen.dart';
import 'package:solardiag_pro/features/studio_workspace.dart';
import 'package:solardiag_pro/features/workspace_shell.dart';
import 'package:solardiag_pro/l10n/generated/app_localizations.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadBundledFonts);

  const viewports = <String, Size>{
    'phone': Size(390, 844),
    'tablet': Size(834, 1194),
    'desktop': Size(1440, 900),
  };
  const locales = [Locale('en'), Locale('ar')];
  final screens = <String, Widget Function()>{
    'home': () => WorkspaceShell(
      onToggleLocale: _noop,
      onToggleTheme: _noop,
      onToggleContrast: _noop,
      onOpenDesignLab: _noop,
      onOpenDiagnostics: _noop,
      onOpenSettings: _noop,
      studioEnabled: false,
      contributionsEnabled: false,
    ),
    'battery_overview': BatteryWorkspace.new,
    'cell_monitoring': () =>
        const BatteryWorkspace(initialSection: BatterySection.cells),
    'cell_bars': () =>
        const BatteryWorkspace(initialSection: BatterySection.cells),
    'cell_heatmap': () =>
        const BatteryWorkspace(initialSection: BatterySection.cells),
    'temperature': () =>
        const BatteryWorkspace(initialSection: BatterySection.temperature),
    'fault_diagnostics': () =>
        const BatteryWorkspace(initialSection: BatterySection.faults),
    'service_functions': () =>
        const BatteryWorkspace(initialSection: BatterySection.service),
    'report_preview': () => const _ReportPreviewFixture(),
    'parameters': ParametersScreen.new,
    'parameters_diff': ParametersScreen.new,
    'parameters_pipeline': () => const _ParameterPipelineFixture(),
    'parameters_failure': () => const _ParameterPipelineFixture(failed: true),
    'link': LinkScreen.new,
    'gateway': GatewayScreen.new,
    'studio': StudioWorkspace.new,
    'inverter': InverterDiagnosticsScreen.new,
    'history': SessionHistoryScreen.new,
    'onboarding': () => const OnboardingScreen(onComplete: _noop),
    'settings': () => const SettingsScreen(
      locale: Locale('en'),
      themeMode: ThemeMode.light,
      onLocaleChanged: _ignoreLocale,
      onThemeModeChanged: _ignoreThemeMode,
      onPreferencesChanged: _noop,
    ),
  };
  const scenarios = <String, SimulationScenario>{
    'cell_monitoring': SimulationScenario.gradualImbalance,
    'cell_bars': SimulationScenario.gradualImbalance,
    'cell_heatmap': SimulationScenario.gradualImbalance,
    'temperature': SimulationScenario.highTemperature,
    'fault_diagnostics': SimulationScenario.electricalEvents,
    'link_compatible': SimulationScenario.inverterPeer,
    'link_limits': SimulationScenario.inverterPeer,
    'link_incompatible': SimulationScenario.inverterPeer,
    'link_unknown': SimulationScenario.communicationFaults,
  };
  const refreshCounts = <String, int>{
    'link_compatible': 1,
    'link_limits': 2,
    'link_incompatible': 3,
    'link_unknown': 3,
  };
  final interactions = <String, Future<void> Function(WidgetTester)>{
    'parameters_diff': (tester) async {
      final edit = find.byKey(const Key('edit-charge-limit'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
    },
    'cell_bars': (tester) async {
      await tester.ensureVisible(find.byType(CellBarChart));
    },
    'cell_heatmap': (tester) async {
      await tester.ensureVisible(find.byType(CellHeatmap));
    },
  };

  screens
    ..remove('link')
    ..addAll({
      'link_compatible': LinkScreen.new,
      'link_limits': LinkScreen.new,
      'link_incompatible': LinkScreen.new,
      'link_unknown': LinkScreen.new,
    });

  for (final screen in screens.entries) {
    for (final viewport in viewports.entries) {
      for (final brightness in Brightness.values) {
        for (final locale in locales) {
          final name = [
            screen.key,
            viewport.key,
            brightness.name,
            locale.languageCode,
          ].join('_');
          testWidgets('core screen golden $name', (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = viewport.value;
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);

            final session = DeviceSession(
              scenario: scenarios[screen.key] ?? SimulationScenario.healthy,
              autoStart: false,
            );
            addTearDown(session.dispose);
            for (
              var refresh = 0;
              refresh < (refreshCounts[screen.key] ?? 1);
              refresh++
            ) {
              await session.refresh();
            }
            await session.refreshParameters();

            await tester.pumpWidget(
              DeviceSessionScope(
                session: session,
                child: DesignPreferenceScope(
                  preferences: DesignPreferences(),
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: solarTheme(brightness: brightness),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(disableAnimations: true),
                      child: child!,
                    ),
                    home: RepaintBoundary(
                      key: const Key('golden-root'),
                      child: Material(child: screen.value()),
                    ),
                  ),
                ),
              ),
            );
            if (screen.key == 'parameters_pipeline') {
              await tester.pump(const Duration(milliseconds: 500));
            } else {
              await tester.pumpAndSettle();
            }
            final interaction = interactions[screen.key];
            if (interaction != null) {
              await interaction(tester);
              await tester.pumpAndSettle();
            }

            await expectLater(
              find.byKey(const Key('golden-root')),
              matchesGoldenFile('core_screens/$name.png'),
            );
          });
        }
      }
    }
  }
}

void _noop() {}
void _ignoreLocale(Locale _) {}
void _ignoreThemeMode(ThemeMode _) {}

Future<void> _loadBundledFonts() async {
  final loaders = [
    FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')),
    FontLoader('IBM Plex Sans Arabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-SemiBold.ttf')),
    FontLoader('JetBrains Mono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Variable.ttf')),
  ];
  await Future.wait(loaders.map((loader) => loader.load()));
}

class _ParameterPipelineFixture extends StatelessWidget {
  const _ParameterPipelineFixture({this.failed = false});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final steps = [
      s.pipelineValidate,
      s.pipelineIdentify,
      s.pipelineBackup,
      s.pipelineAuthorize,
      s.pipelineConfirm,
      s.pipelineWrite,
      s.pipelineReadback,
      s.pipelineVerify,
      s.pipelineAudit,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(s.parameters)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DiffReviewSheet(
            title: s.simulatedWritePipeline,
            items: [
              DiffReviewItem(
                label: s.chargeVoltageLimit,
                before: '55.2 V',
                after: '54.8 V',
                validationMessage: failed ? s.writeFailedVerify : null,
              ),
            ],
            stepLabels: steps,
            currentStep: failed ? 7 : 5,
            loading: !failed,
            confirmLabel: s.confirmSimulatedWrite,
            cancelLabel: s.cancel,
          ),
          if (failed) ...[
            const SizedBox(height: 16),
            SafetyBanner(
              title: s.writeFailedVerify,
              message: s.restoreBackupConfirmation(1),
              status: SolarStatus.critical,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportPreviewFixture extends StatelessWidget {
  const _ReportPreviewFixture();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.reportPreview)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ReportPreview(
            title: s.reportPreview,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(s.simulatorValuesNotice),
                const SizedBox(height: 24),
                ParameterRow(title: s.packVoltage, detail: '51.24', unit: 'V'),
                ParameterRow(title: s.cellDelta, detail: '4.0', unit: 'mV'),
                const Spacer(),
                SimulatedBadge(label: s.simulated),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
