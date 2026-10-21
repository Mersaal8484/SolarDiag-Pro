import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/features/battery_workspace.dart';
import 'package:solardiag_pro/features/gateway_screen.dart';
import 'package:solardiag_pro/features/link_screen.dart';
import 'package:solardiag_pro/features/parameters_screen.dart';
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
      studioEnabled: false,
      contributionsEnabled: false,
    ),
    'battery': BatteryWorkspace.new,
    'parameters': ParametersScreen.new,
    'link': LinkScreen.new,
    'gateway': GatewayScreen.new,
    'studio': StudioWorkspace.new,
  };

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
              scenario: SimulationScenario.healthy,
              autoStart: false,
            );
            addTearDown(session.dispose);
            await session.refresh();
            await session.refreshParameters();

            await tester.pumpWidget(
              DeviceSessionScope(
                session: session,
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
            );
            await tester.pumpAndSettle();

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

Future<void> _loadBundledFonts() async {
  final loaders = [
    FontLoader('MaterialIcons')..addFont(_loadMaterialIcons()),
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

Future<ByteData> _loadMaterialIcons() async {
  final executable = File(Platform.resolvedExecutable);
  final inferredRoot = executable.parent.parent.parent.parent.parent.path;
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? inferredRoot;
  final separator = Platform.pathSeparator;
  final font = File(
    '$flutterRoot${separator}bin${separator}cache${separator}artifacts'
    '${separator}material_fonts${separator}MaterialIcons-Regular.otf',
  );
  final bytes = await font.readAsBytes();
  return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
}
