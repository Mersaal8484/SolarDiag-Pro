import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/design/accessibility.dart';
import 'package:solardiag_pro/design/components.dart';
import 'package:solardiag_pro/design/solar_icons.g.dart';
import 'package:solardiag_pro/l10n/generated/app_localizations.dart';

void main() {
  test('ARB locales have identical message keys', () {
    Set<String> keys(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>).keys
            .where((key) => !key.startsWith('@'))
            .toSet();
    expect(keys('lib/l10n/app_ar.arb'), keys('lib/l10n/app_en.arb'));
  });

  test('symbol inventory is complete and every SVG source exists', () {
    expect(SolarIcons.all.length, greaterThanOrEqualTo(70));
    for (final icon in SolarIcons.all) {
      expect(File(icon.asset).existsSync(), isTrue, reason: icon.name);
    }
    expect(SolarIcons.currentFlow.directional, isTrue);
    expect(SolarIcons.socRing.directional, isFalse);
  });

  test('digit preferences and technical isolation are deterministic', () {
    expect(localizedDigits('51.2', DigitPreference.western), '51.2');
    expect(localizedDigits('51.2', DigitPreference.arabicIndic), '٥١.٢');
  });

  test('feature code has no direct colors or literal Text widgets', () {
    final offenders = <String>[];
    final directColor = RegExp(r'\bColors\.|Color\(0x');
    final literalText = RegExp(
      r'''(?:const\s+)?\bText\(\s*['\"][A-Za-z\u0600-\u06ff]''',
    );
    for (final file
        in Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      expect(source.contains('AppStrings'), isFalse, reason: file.path);
      expect(source.contains('.pick('), isFalse, reason: file.path);
      if (directColor.hasMatch(source) || literalText.hasMatch(source)) {
        offenders.add(file.path);
      }
      expect(source.contains('الإنفرتر'), isFalse, reason: file.path);
    }
    expect(offenders, isEmpty);
  });

  test('transport layer never imports Studio capture types', () {
    final offenders = <String>[];
    for (final file
        in Directory('lib/transport')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      if (source.contains('studio/capture_models.dart') ||
          source.contains('CapturedFrame') ||
          source.contains('CaptureFrame')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  testWidgets('technical measurements and cell order stay LTR in Arabic', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: solarTheme(brightness: Brightness.light),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 300,
                  child: MetricTile(
                    label: 'جهد الحزمة',
                    value: '51.24',
                    unit: 'V',
                    updatedLabel: 'الآن',
                  ),
                ),
                SizedBox(
                  width: 300,
                  height: 180,
                  child: CellGrid(values: [3.1, 3.2]),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final metric = find.byType(MetricTile);
    final value = find.descendant(of: metric, matching: find.text('51.24'));
    final unit = find.descendant(of: metric, matching: find.text('V'));
    expect(tester.getCenter(value).dx, lessThan(tester.getCenter(unit).dx));
    expect(
      tester.getCenter(find.text('1')).dx,
      lessThan(tester.getCenter(find.text('2')).dx),
    );
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'components render ${locale.languageCode} $brightness with semantics',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: solarTheme(brightness: brightness),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      MetricTile(
                        label: 'Pack voltage',
                        value: '51.2',
                        unit: 'V',
                        updatedLabel: 'Updated now',
                        simulated: true,
                      ),
                      RingGauge(value: .8, label: 'State of charge'),
                      ConnectionCapsule(
                        gateway: 'Gateway',
                        interfaceName: 'CAN',
                        device: 'BMS',
                        profile: 'SIM',
                        mode: 'MONITOR',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.bySemanticsLabel(RegExp('51\\.2')), findsOneWidget);
        },
      );
    }
  }
}
