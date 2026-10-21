import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/features/design_lab.dart';
import 'package:solardiag_pro/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadBundledFonts);

  const viewports = <String, Size>{
    'phone': Size(390, 844),
    'tablet': Size(834, 1194),
    'desktop': Size(1440, 900),
  };
  const locales = [Locale('en'), Locale('ar')];

  for (final viewport in viewports.entries) {
    for (final brightness in Brightness.values) {
      for (final locale in locales) {
        final name = [
          viewport.key,
          brightness.name,
          locale.languageCode,
        ].join('_');
        testWidgets('Design Lab golden $name', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.value;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            MaterialApp(
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
              home: const RepaintBoundary(child: DesignLab()),
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(DesignLab),
            matchesGoldenFile('design_lab/$name.png'),
          );
        });
      }
    }
  }
}

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
