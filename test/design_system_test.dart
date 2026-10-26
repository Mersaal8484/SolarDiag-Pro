import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/design/accessibility.dart';
import 'package:solardiag_pro/design/components.dart';
import 'package:solardiag_pro/design/solar_icons.g.dart';
import 'package:solardiag_pro/design/value_unit_formatter.dart';
import 'package:solardiag_pro/features/battery_workspace.dart';
import 'package:solardiag_pro/features/device_library.dart';
import 'package:solardiag_pro/features/parameters_screen.dart';
import 'package:solardiag_pro/features/settings_screen.dart';
import 'package:solardiag_pro/features/studio_workspace.dart';
import 'package:solardiag_pro/l10n/generated/app_localizations.dart';
import 'package:solardiag_pro/l10n/generated/app_localizations_ar.dart';
import 'package:solardiag_pro/persistence/local_database.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/trust/library_write_reason.dart';

void main() {
  test('ARB locales have identical message keys', () {
    Set<String> keys(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>).keys
            .where((key) => !key.startsWith('@'))
            .toSet();
    expect(keys('lib/l10n/app_ar.arb'), keys('lib/l10n/app_en.arb'));
  });

  test('symbol inventory is complete and every SVG source exists', () {
    const required = {
      'home',
      'inverter',
      'battery',
      'link-diagnostics',
      'library',
      'history',
      'gateway',
      'can-bus',
      'rs485',
      'rs232',
      'uart',
      'ble',
      'usb',
      'wifi',
      'cell',
      'cell-grid',
      'soc-ring',
      'soh',
      'cycle',
      'balancing',
      'mosfet',
      'contactor',
      'temperature',
      'thermal-map',
      'current-flow',
      'parallel-bank',
      'master-slave',
      'healthy',
      'warning',
      'critical',
      'stale',
      'offline',
      'locked',
      'unlocked-verified',
      'simulated',
      'verified-hardware',
      'verified-document',
      'research',
      'read-only',
      'configure',
      'calibrate',
      'factory',
      'backup',
      'restore',
      'compare',
      'report',
      'export',
      'share',
      'search',
      'filter',
      'record',
      'solar',
      'grid',
      'load',
      'battery-charge',
      'battery-discharge',
      'capture-record',
      'passive-tap',
      'hex-inspector',
      'frame',
      'request-response',
      'diff',
      'hypothesis',
      'evidence',
      'confirmed-check',
      'profile-builder',
      'register-map',
      'replay-lock',
      'contribute',
      'redact',
      'review-queue',
      'signed-profile',
      'revoked',
      'library-sync',
      'reward-points',
      'role',
    };
    expect(SolarIcons.all.map((icon) => icon.name).toSet(), required);
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

  test('J2 feature controls do not use Material dropdown widgets', () {
    final offenders = <String>[];
    final materialDropdown = RegExp(r'\bDropdownButton(?:FormField)?\b');
    for (final file
        in Directory('lib/features')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      if (materialDropdown.hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('R6 direct Material icon usage follows the shrinking allowlist', () {
    final allowlist = File('test/architecture/material_icon_allowlist.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();
    final occurrences = <String>{};
    final directMaterialIcon = RegExp(r'\bIcons\.[A-Za-z_]\w*');
    for (final directory in ['lib/features', 'lib/design']) {
      for (final file
          in Directory(directory)
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        if (directMaterialIcon.hasMatch(file.readAsStringSync())) {
          occurrences.add(file.path.replaceAll('\\', '/'));
        }
      }
    }
    expect(allowlist, isEmpty, reason: 'The R6 allowlist may only shrink.');
    expect(occurrences, allowlist);
  });

  testWidgets('R6 library explains when no production trust anchor exists', (
    tester,
  ) async {
    await _pumpAtDoubleTextScale(
      tester,
      const Locale('en'),
      const Scaffold(
        body: DeviceLibraryScreen(
          writeDisabledReason: LibraryWriteDisabledReason.noValidTrustAnchor,
        ),
      ),
    );
    expect(
      find.text(
        'No valid production trust anchor is configured. '
        'Signed library updates and physical writes remain blocked.',
      ),
      findsOneWidget,
    );
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final reason in LibraryWriteDisabledReason.values) {
      testWidgets(
        'R6 parameters localize ${reason.name} in ${locale.languageCode}',
        (tester) async {
          final session = DeviceSession(autoStart: false);
          addTearDown(session.dispose);
          final blocksWrites =
              reason != LibraryWriteDisabledReason.libraryMissing;
          session.setLibraryWriteStatus(
            reason: reason,
            blocksWrites: blocksWrites,
          );
          await _pumpAtDoubleTextScale(
            tester,
            locale,
            DeviceSessionScope(
              session: session,
              child: const Scaffold(body: ParametersScreen()),
            ),
          );
          expect(session.libraryWritesBlocked, blocksWrites);
          expect(
            find.text(_expectedWriteBlockReason(reason, locale)),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('R6 cell tiles remain within bounds at 200% text in '
        '${locale.languageCode}', (tester) async {
      await _pumpAtDoubleTextScale(
        tester,
        locale,
        const Scaffold(
          body: SizedBox(
            width: 300,
            child: CellGrid(values: [3.1, 3.2, 3.3, 3.4]),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'R6 connection capsule wraps at 200% text in ${locale.languageCode}',
      (tester) async {
        await _pumpAtDoubleTextScale(
          tester,
          locale,
          const Scaffold(
            body: SizedBox(
              width: 280,
              child: ConnectionCapsule(
                gateway: 'Diagnostic gateway',
                interfaceName: 'Virtual CAN interface',
                device: 'Simulated battery manager',
                profile: 'Long profile identifier',
                mode: 'Read-only monitoring mode',
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Read-only monitoring mode'), findsOneWidget);
      },
    );

    testWidgets('R7 golden handoff controls fit narrow width at 200% text in '
        '${locale.languageCode}', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 1200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpAtDoubleTextScale(
        tester,
        locale,
        const _GoldenHandoffControlsFixture(),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'R7 report preview fits phone width in ${locale.languageCode}',
      (tester) async {
        tester.view
          ..physicalSize = const Size(390, 844)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpLocalized(
          tester,
          locale,
          const _GoldenReportPreviewFixture(),
          textScale: 1,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('R6 battery card width scales in ${locale.languageCode}', (
      tester,
    ) async {
      final session = DeviceSession(autoStart: false);
      addTearDown(session.dispose);
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpAtDoubleTextScale(
        tester,
        locale,
        DeviceSessionScope(
          session: session,
          child: const Scaffold(
            body: BatteryWorkspace(initialSection: BatterySection.cells),
          ),
        ),
      );
      final cellCard = find.byKey(const Key('battery-cell-card-1'));
      await tester.scrollUntilVisible(
        cellCard,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(cellCard).width, closeTo(342, 1));
    });

    testWidgets(
      'R6 cycle count has no fractional digits in ${locale.languageCode}',
      (tester) async {
        final session = DeviceSession(autoStart: false);
        addTearDown(session.dispose);
        final preferences = DesignPreferences()
          ..digits = DigitPreference.arabicIndic;
        addTearDown(preferences.dispose);
        await _pumpAtDoubleTextScale(
          tester,
          locale,
          DesignPreferenceScope(
            preferences: preferences,
            child: DeviceSessionScope(
              session: session,
              child: const Scaffold(
                body: BatteryWorkspace(initialSection: BatterySection.overview),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final expectedCycleLabel = locale.languageCode == 'ar'
            ? '٢١٤ دورة'
            : '٢١٤ cycles';
        expect(find.textContaining(expectedCycleLabel), findsOneWidget);
        expect(find.textContaining('٢١٤.٠'), findsNothing);
      },
    );

    testWidgets(
      'R6 frame IDs and counts are integral in ${locale.languageCode}',
      (tester) async {
        final database = LocalDatabase.inMemory();
        addTearDown(database.close);
        final preferences = DesignPreferences()
          ..digits = DigitPreference.arabicIndic;
        addTearDown(preferences.dispose);
        await _pumpAtDoubleTextScale(
          tester,
          locale,
          DesignPreferenceScope(
            preferences: preferences,
            child: StudioWorkspace(database: database),
          ),
        );
        await tester.tap(find.text('Analysis'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final technicalLabels = tester
            .widgetList<TechnicalText>(find.byType(TechnicalText))
            .map((widget) => widget.data)
            .toList();
        final expectedFrameLabel = locale.languageCode == 'ar'
            ? '٣ إطارات'
            : '٣ frames';
        expect(technicalLabels, contains('0x351'));
        expect(
          technicalLabels.any((label) => label.contains(expectedFrameLabel)),
          isTrue,
        );
        expect(
          technicalLabels.any(
            (label) => RegExp(r'\d+\.\d+ frames').hasMatch(label),
          ),
          isFalse,
        );
      },
    );
  }

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

  test('value and unit formatter applies precision, digits, and isolation', () {
    const western = ValueUnitFormatter();
    const arabic = ValueUnitFormatter(useArabicIndicDigits: true);

    expect(western.number(214.0), '214');
    expect(
      western.format(51.2, unit: EngineeringUnit.volts, isolate: true),
      '\u206651.20 V\u2069',
    );
    expect(
      arabic.format(214, unit: EngineeringUnit.volts, unitLabel: 'فولت'),
      '٢١٤.٠٠ فولت',
    );
  });

  test('Arabic engineering quantities use ICU plural categories', () {
    final arabic = AppLocalizationsAr();
    expect(localizedUnitLabel(arabic, EngineeringUnit.volts), 'فولت');
    expect(localizedUnitLabel(arabic, EngineeringUnit.millivolts), 'ملي فولت');
    expect(arabic.cycleValue(0, '٠'), 'لا دورات');
    expect(arabic.cycleValue(1, '١'), 'دورة واحدة');
    expect(arabic.cycleValue(2, '٢'), 'دورتان');
    expect(arabic.cycleValue(7, '٧'), '٧ دورات');
    expect(arabic.cycleValue(15, '١٥'), '١٥ دورة');
    expect(arabic.sampleValue(0, '٠'), 'لا عينات');
    expect(arabic.sampleValue(1, '١'), 'عينة واحدة');
    expect(arabic.sampleValue(2, '٢'), 'عينتان');
    expect(arabic.sampleValue(7, '٧'), '٧ عينات');
    expect(arabic.sampleValue(15, '١٥'), '١٥ عينة');
    expect(arabic.frameValue(0, '٠'), 'لا إطارات');
    expect(arabic.frameValue(1, '١'), 'إطار واحد');
    expect(arabic.frameValue(2, '٢'), 'إطاران');
    expect(arabic.frameValue(7, '٧'), '٧ إطارات');
    expect(arabic.frameValue(15, '١٥'), '١٥ إطارًا');
    expect(arabic.sampleCoverage(0, '٠', '١٠'), 'لا عينات مبلغ عنها من أصل ١٠');
    expect(arabic.sampleCoverage(1, '١', '١٠'), '١ من أصل ١٠ عينة');
    expect(arabic.sampleCoverage(2, '٢', '١٠'), '٢ من أصل ١٠ عينتين');
    expect(arabic.sampleCoverage(7, '٧', '١٠'), '٧ من أصل ١٠ عينات');
    expect(arabic.sampleCoverage(15, '١٥', '١٠'), '١٥ من أصل ١٠ عينة');
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
    await tester.scrollUntilVisible(
      find.text('Outdoor high contrast'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    final unit = find.descendant(of: metric, matching: find.text('فولت'));
    expect(tester.getCenter(value).dx, lessThan(tester.getCenter(unit).dx));
    expect(
      tester.getCenter(find.text('1')).dx,
      lessThan(tester.getCenter(find.text('2')).dx),
    );
  });

  testWidgets('mode and alarm state changes are live semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: solarTheme(brightness: Brightness.light),
        home: const Scaffold(
          body: Column(
            children: [
              ModeBadge(label: 'READ-ONLY', status: SolarStatus.info),
              AlarmCard(
                title: 'Overvoltage',
                message: 'Raw alarm code: CELL_OVERVOLTAGE',
                status: SolarStatus.critical,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    try {
      expect(
        tester
            .getSemantics(find.byType(StatusPill))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.byType(AlarmCard))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    } finally {
      semantics.dispose();
    }
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

String _expectedWriteBlockReason(
  LibraryWriteDisabledReason reason,
  Locale locale,
) {
  final isArabic = locale.languageCode == 'ar';
  return switch (reason) {
    LibraryWriteDisabledReason.noValidTrustAnchor =>
      isArabic
          ? 'لم يتم إعداد مرساة ثقة إنتاجية صالحة. '
                'تظل تحديثات المكتبة الموقعة والكتابة الفعلية محظورة.'
          : 'No valid production trust anchor is configured. '
                'Signed library updates and physical writes remain blocked.',
    LibraryWriteDisabledReason.libraryMissing =>
      isArabic
          ? 'لم تُثبّت مكتبة أجهزة موثّقة. '
                'تظل الكتابة على الأجهزة الفعلية محظورة.'
          : 'No verified device library is installed. '
                'Physical library writes remain blocked.',
    LibraryWriteDisabledReason.revoked =>
      isArabic
          ? 'حُظرت حزمة المكتبة النشطة أو ملف الجهاز. '
                'تظل الكتابة على الأجهزة الفعلية محظورة.'
          : 'The active library pack or profile is revoked. '
                'Physical library writes remain blocked.',
    LibraryWriteDisabledReason.stale =>
      isArabic
          ? 'بيانات الإلغاء قديمة. '
                'حدّثها قبل تمكين الكتابة على الأجهزة الفعلية.'
          : 'The revocation data is stale. '
                'Refresh it before physical writes can be enabled.',
    LibraryWriteDisabledReason.revocationListExpired =>
      isArabic
          ? 'انتهت صلاحية قائمة الإلغاء. '
                'حدّثها قبل تمكين الكتابة على الأجهزة الفعلية.'
          : 'The revocation list has expired. '
                'Refresh it before physical writes can be enabled.',
  };
}

Future<void> _pumpAtDoubleTextScale(
  WidgetTester tester,
  Locale locale,
  Widget child,
) => _pumpLocalized(tester, locale, child, textScale: 2);

Future<void> _pumpLocalized(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  required double textScale,
}) async {
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
      theme: solarTheme(brightness: Brightness.light),
      builder: (context, content) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: content!,
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

class _GoldenHandoffControlsFixture extends StatelessWidget {
  const _GoldenHandoffControlsFixture();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: 280,
              child: MetricTile(
                label: s.packVoltage,
                value: '51.24',
                unit: 'V',
                updatedLabel: s.updatedNow,
                simulated: true,
              ),
            ),
            const SizedBox(height: 24),
            DiffReviewSheet(
              title: s.simulatedWritePipeline,
              items: [
                DiffReviewItem(
                  label: s.chargeVoltageLimit,
                  before: '55.2 V',
                  after: '54.8 V',
                  validationMessage: s.writeFailedVerify,
                ),
              ],
              confirmLabel: s.confirmSimulatedWrite,
              cancelLabel: s.cancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldenReportPreviewFixture extends StatelessWidget {
  const _GoldenReportPreviewFixture();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
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
