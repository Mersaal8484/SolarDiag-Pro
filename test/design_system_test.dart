import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/design/accessibility.dart';
import 'package:solardiag_pro/design/components.dart';
import 'package:solardiag_pro/design/solar_icons.g.dart';
import 'package:solardiag_pro/features/settings_screen.dart';
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

  test('D1 components are concrete widgets rather than inheritance aliases', () {
    final source = File('lib/design/components.dart').readAsStringSync();
    const componentNames = [
      'DeltaBar',
      'Sparkline',
      'TrendChart',
      'ThermalMap',
      'AlarmCard',
      'TimelineEvent',
      'ParameterRow',
      'DiffReviewSheet',
      'AuthorizationSheet',
      'ProfileCard',
      'LinkDiagram',
      'ReportPreview',
      'HexGrid',
      'FrameTimeline',
      'ConversationLane',
      'DiffView',
      'HypothesisCard',
      'RedactionPreview',
      'ConsentSheet',
      'ContributionStatusStepper',
      'LibraryUpdateCard',
      'ModeBadge',
      'VerificationBadge',
      'ConfidenceBadge',
      'RoleBadge',
      'SignedBadge',
      'EvidenceChip',
    ];
    for (final name in componentNames) {
      expect(
        RegExp(
          'class $name extends (SolarLabeledPanel|TimelineEvent|DiffReviewSheet|SafetyBanner|StatusPill)',
        ).hasMatch(source),
        isFalse,
        reason: name,
      );
    }
    expect(source.contains('0.7, 0.4, 0.6, 0.2, 0.35'), isFalse);
    expect(source.contains("'01 03 00 00 00 02'"), isFalse);
  });

  test('D2 feature and design layers do not use Material icon glyphs', () {
    final offenders = <String>[];
    for (final directory in ['lib/design', 'lib/features']) {
      for (final file
          in Directory(directory)
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        if (RegExp(r'(?<!Solar)Icons\.|\bIcon\(').hasMatch(source)) {
          offenders.add(file.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('D3 deprecated color aliases are absent from application code', () {
    final offenders = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      if (file.readAsStringSync().contains('SolarColors.')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('D3 application layers obtain colors from theme tokens', () {
    final offenders = <String>[];
    final directColor = RegExp(r'\bColors\.|Color\(0x');
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final normalized = file.path.replaceAll('\\', '/');
      if (normalized.startsWith('lib/design/') ||
          normalized == 'lib/app/theme.dart') {
        continue;
      }
      if (directColor.hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('D5 Arabic glossary uses العاكس and rejects the loanword', () {
    final arabic = File('lib/l10n/app_ar.arb').readAsStringSync();
    expect(arabic, contains('العاكس'));
    expect(arabic, isNot(contains('الإنفرتر')));
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
    final literalTechnicalText = RegExp(
      r'''(?:const\s+)?\bTechnicalText\(\s*['\"][A-Za-z\u0600-\u06ff]''',
    );
    for (final file
        in Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      expect(source.contains('AppStrings'), isFalse, reason: file.path);
      expect(source.contains('.pick('), isFalse, reason: file.path);
      if (directColor.hasMatch(source) ||
          literalText.hasMatch(source) ||
          literalTechnicalText.hasMatch(source)) {
        offenders.add(file.path);
      }
      expect(source.contains('الإنفرتر'), isFalse, reason: file.path);
    }
    expect(offenders, isEmpty);
  });

  testWidgets('settings expose persisted accessibility controls', (
    tester,
  ) async {
    final preferences = DesignPreferences();
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      DesignPreferenceScope(
        preferences: preferences,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: solarTheme(brightness: Brightness.light),
          home: SettingsScreen(
            locale: const Locale('en'),
            themeMode: ThemeMode.light,
            onLocaleChanged: (_) {},
            onThemeModeChanged: (_) {},
            onPreferencesChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Digit preference'), findsOneWidget);
    expect(find.text('Workshop mode'), findsOneWidget);
    expect(find.text('Outdoor high contrast'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Time axis left to right'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Time axis left to right'), findsOneWidget);
    expect(find.text('Reduce transparency'), findsOneWidget);

    await tester.ensureVisible(find.text('Arabic-Indic (٠–٩)'));
    await tester.tap(find.text('Arabic-Indic (٠–٩)'));
    await tester.pump();
    expect(preferences.digits, DigitPreference.arabicIndic);
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
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
